class Admin::PurchasesController < Admin::BaseController
  include ApplyDiscount
  # reinclude once refactoring done, then replace dop = DateTime.new.. code in dop_change
  # include ParamsDateConstructor  
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :superadmin_account, only: :analysis
  before_action :initialize_sort, only: :index
  before_action :set_purchase, only: [:show, :edit, :update, :destroy, :expire]
  before_action :sanitize_params, only: [:create, :update]
  # https://stackoverflow.com/questions/30221810/rails-pass-params-arguments-to-activerecord-callback-function
  # parameter is an array to deal with the situation where eg a wkclass is deleted and multiple purchases need updating
  # this approach is no good as the callback should be after a successful create not a failed create
  # after_action -> { update_purchase_status([@purchase]) }, only: [:create, :update]

  def index
    # @purchases = Purchase.includes(:bookings, :product, :freezes, :adjustments, :client)
    # associations referred to in view - bookings, product in start_to_expiry method, client directly in purchase.client.name
    @purchases = Purchase.includes(:bookings, :freezes, :adjustments, :penalties, :client, :restart_as_parent, product: [:workout_group])
    @superadmin = logged_in_as?('superadmin')
    handle_search
    handle_filter
    handle_period
    @purchases_all_pages_sum = Purchase.where(id: @purchases.pluck(:id)).sum(:charge) if logged_in_as?('admin', 'superadmin')
    handle_sort
    prepare_items_for_filters
    handle_pagination
    handle_index_response
  end
  
  
  def show
    @discounts = @purchase.discounts
    @bookings_no_amnesty = @purchase.bookings.no_amnesty.merge(Booking.order_by_date)
    @bookings_amnesty = @purchase.bookings.amnesty.merge(Booking.order_by_date)
    @frozen_now = @purchase.freezed?(Time.zone.now)
    sunset_hash
    @link_from = params[:link_from]
    handle_show_response
  end
  
  def new
    @purchase = Purchase.new
    prepare_items_for_dropdowns
    @form_cancel_link = purchases_path
    payment = @purchase.build_payment    
  end
  
  def edit
    @form_cancel_link = params[:link_from] == 'show' ? purchase_path(@purchase) : purchases_path
    prepare_items_for_dropdowns
    handle_show_response    
  end
  
  def create
    @purchase = Purchase.new(purchase_params)
    if @purchase.save
      # make dry - repeated in update method
      [:renewal_discount_id, :status_discount_id, :oneoff_discount_id, :commercial_discount_id, :discretion_discount_id].each do |discount|
        DiscountAssignment.create(purchase_id: @purchase.id, discount_id: params[:purchase][discount].to_i) if params[:purchase][discount]
      end
      # equivalent to redirect_to purchase_path @purchase
      # redirect_to [:admin, @purchase]
      redirect_to purchases_path
      flash_message :success, t('.success')
      post_purchase_processing
      create_rider if @purchase.product.has_rider?
    else
      prepare_items_for_dropdowns
      render :new, status: :unprocessable_entity
    end
  end
  
  def update
    if @purchase.update(purchase_params)
      # if the edit does not change the discounts, then no further action, otherwise delete all the purchases existing DiscountAssignments and create new ones
      existing_discounts = DiscountAssignment.where(purchase_id: @purchase.id).pluck(:discount_id).sort
      updated_discounts = [:renewal_discount_id, :status_discount_id, :oneoff_discount_id, :commercial_discount_id, :discretion_discount_id].map do |d|
        params[:purchase][d]
      end.compact.sort
      unless existing_discounts == updated_discounts
        DiscountAssignment.where(purchase_id: @purchase.id).destroy_all
        [:renewal_discount_id, :status_discount_id, :oneoff_discount_id, :commercial_discount_id, :discretion_discount_id].each do |discount|
          DiscountAssignment.create(purchase_id: @purchase.id, discount_id: params[:purchase][discount].to_i) if params[:purchase][discount]
        end
      end
      redirect_to @purchase
      flash_message :success, t('.success')
      update_purchase_status([@purchase])
    else
      @form_cancel_link = params[:purchase][:link_from] == 'show' ? purchase_path(@purchase, link_from: 'show') : purchases_path
      # @form_cancel_link = params[:link_from] == 'show' ? purchase_path(@purchase) : purchases_path
      # @form_cancel_link = params[:purchase][:link_from] == 'purchases_index' ? client_path(@client, link_from: 'purchases_index') : clients_path
      prepare_items_for_dropdowns
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @purchase.destroy
    redirect_to purchases_path
    flash_message :success, t('.success', name: @purchase.client.name)
  end
  
  def client_filter
    clear_session(:select_client_name)
    session[:select_client_name] = params[:select_client_name] || session[:select_client_name]
    @clients = Client.order_by_first_name
    @selected_client_index = (@clients.index(@clients.first_name_like(session[:select_client_name]).first) || 0) + 1
    render json: { selected_client_index: @selected_client_index }
    # redirect_to new_purchase_path
  end
  
  def clear_filters
    # *splat operator is used to turn array into an argument list
    # https://ruby-doc.org/core-2.0.0/doc/syntax/calling_methods_rdoc.html#label-Array+to+Arguments+Conversion
    clear_session(*session_filter_list)
    redirect_to purchases_path
  end
  
  def filter
    clear_session(*session_filter_list)
    session[:search_name] = params[:search_name]
    session[:purchases_period] = params[:purchases_period]
    (params_filter_list - [:search_name, :purchases_period]).each do |item|
      session["filter_#{item}".to_sym] = params[item]
    end
    redirect_to purchases_path
  end
  
  def expire
    if @purchase.expired?
      @purchase.update(status: @purchase.status_calc, expiry_date: @purchase.expiry_date_calc)
      flash_message :success, t('.unexpired', name: @purchase.client.name)
    else
      @purchase.update(status: 'expired', expiry_date: @purchase.sunset_date)
      flash_message :success, t('.success', name: @purchase.client.name)
    end
    redirect_to @purchase
  end
  
  def analysis
    @purchase_years = purchase_years
    @product_display_limit = Rails.application.config_for(:constants)['product_piechart_display_limit']
  end
  
  def form_field_change
    # dop = construct_date(params, 'dop')
    dop = check_dop_valid
    if dop.nil?
      render json: { dop: 'invalid' }
    else
      discount_none = Discount.joins(:discount_reason).where(discount_reasons: { rationale: 'Base' }).first
      renewal_discount = (discount_options('renewal', dop, discount_none).include? Discount.find(params[:renewal_discount_id])) ? Discount.find(params[:renewal_discount_id]) : discount_none
      status_discount = (discount_options('status', dop, discount_none).include? Discount.find(params[:status_discount_id])) ? Discount.find(params[:status_discount_id]) : discount_none
      # status_discount = Discount.find(params[:status_discount_id])
      commercial_discount = Discount.find(params[:commercial_discount_id])
      discretion_discount = Discount.find(params[:discretion_discount_id])
      oneoff_discount = Discount.find(params[:oneoff_discount_id])
      # base_price = Price.base_at(Time.zone.now).find_by(product_id: params[:product_id])
      base_price = Price.base_at(dop).find_by(product_id: params[:product_id])
      payment_after_discount = apply_discount(base_price, renewal_discount, status_discount, oneoff_discount, discretion_discount, commercial_discount)    
      render json: { renewal: helpers.collection_select(:purchase, :renewal_discount_id, discount_options('renewal', dop, discount_none), :id, :name,
      selected: params[:renewal_discount_id] || discount_none.id),
      status: helpers.collection_select(:purchase, :status_discount_id, discount_options('status', dop, discount_none), :id, :name,
      selected: params[:status_discount_id] || discount_none.id),
      commercial: helpers.collection_select(:purchase, :commercial_discount_id, discount_options('commercial', dop, discount_none), :id, :name,
      selected: params[:commercial_discount_id] || discount_none.id),
      discretion: helpers.collection_select(:purchase, :discretion_discount_id, discount_options('discretion', dop, discount_none), :id, :name,
      selected: params[:discretion_discount_id] || discount_none.id),
      oneoff: helpers.collection_select(:purchase, :oneoff_discount_id, discount_options('oneoff', dop, discount_none), :id, :name,
      selected: params[:oneoff_discount_id] || discount_none.id),
      base_price_id: base_price&.id,
      base_price_price: base_price&.price,
      payment_after_discount: payment_after_discount }
    end
    
  end
  
  private
  
  def check_dop_valid
    # eg administrator could enter 31 Feb by mistake
    return DateTime.new(params[:dop_1i].to_i,
    params[:dop_2i].to_i,
    params[:dop_3i].to_i)
    
  rescue
    nil
  end

  def discount_options(discount_type, date, discount_none)
    [discount_none] + Discount.with_rationale_at(discount_type.capitalize, date)
  end

  def create_rider
    rider_product = Product.where(rider: true).first
    rider_product_price = rider_product.base_price_at(Time.zone.now)
    @rider_purchase = @purchase.dup
    if @rider_purchase.update({ product_id: rider_product.id,
                                charge: 0,
                                note: nil,
                                price_id: rider_product_price.id,
                                purchase_id: @purchase.id })
      flash_message :success, t('.rider_success')
    else
      flash_message :warning, t('.rider_fail')
    end
  end

  def sunset_hash
    @sunset_hash = {}
    @sunset_hash[:action] = @purchase.sunset_action
    if @sunset_hash[:action] == :sunset
      @sunset_hash[:image] = 'bi-sunset'
      @sunset_hash[:confirm] = 'This purchase will be expired. Are you sure?'
    else
      @sunset_hash[:image] = 'bi-sunrise'
      @sunset_hash[:confirm] = 'This purchase will be recovered from expiry. Are you sure?'
    end
  end

  def new_purchase?
    return true if request.post?

    false
  end

  def restart
    new_purchase = @purchase.dup
    new_purchase.update(status: 'not started' )
    flash_message :warning, t('.restart')
    redirect_to purchases_path
  end

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def purchase_params
    params.require(:purchase)
    .permit(:client_id, :product_id, :price_id, :charge, :dop, :note, :renewal_discount_id, :status_discount_id, :oneoff_discount_id,
    :commercial_discount_id, :discretion_discount_id, payment_attributes: [:dop, :amount, :payment_mode, :note])
  end

  def sanitize_params
    nillify_when_blank(params[:purchase], :note)
    [:renewal_discount_id, :status_discount_id, :oneoff_discount_id, :commercial_discount_id, :discretion_discount_id].each do |discount|
      params[:purchase][discount] = nil if params[:purchase][discount].nil? || Discount.find(params[:purchase][discount]).discount_reason.rationale == 'Base'
    end
    # params[:purchase].tap do |params|
    #   # Fitternity is redundant
    #   # params[:fitternity_id] = Fitternity.ongoing.first&.id if params[:payment_mode] == 'Fitternity'
    #   # prevent ar_date becoming not nil after an update
    #   # checkbox values in form are strings
    #   # adjust and restart checkbox on form hides/displays a&r payment/date but doesn't itself set their values to nil/zero. Don't want to potentially have unwanted entries saved to the database.  
    #   if params[:restart] == '0'
    #     params['ar_date(1i)'] = ''
    #     params['ar_date(2i)'] = ''
    #     params['ar_date(3i)'] = ''
    #     params['ar_payment'] = 0
    #   end
    # end
  end

  def initialize_sort
    session[:sort_option] = params[:sort_option] || session[:sort_option] || 'client_dop'
  end

  def handle_search
    return if session[:search_name].blank?

    @purchases = @purchases.client_name_like(session[:search_name])
  end

  def handle_filter
    # arity doesn't work with scopes so struggled to reformat this further. eg Purchase.method(:classpass).arity returns -1 not zero.
    %w[classpass close_to_expiry fixed main_purchase package_not_trial remind_to_renew rider sunsetted sunset_passed trial unlimited unpaid
       written_off].each do |key|
      @purchases = @purchases.send(key) if session["filter_#{key}"].present?
      # some scopes will return an array (not an ActiveRecord) eg close_to_expiry so
      # HACK: convert back to ActiveRecord for the order_by scopes of the index method, which will fail on an Array
      @purchases = Purchase.where(id: @purchases.map(&:id)) if @purchases.is_a?(Array)
    end
    %w[workout_group statuses].each do |key|
      @purchases = @purchases.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
    end
  end

  def handle_period
    return unless session[:purchases_period].present? && session[:purchases_period] != 'All'

    @purchases = @purchases.during(month_period(session[:purchases_period]))
  end

  def prepare_items_for_filters
    @workout_group = WorkoutGroup.distinct.pluck(:name).sort!
    @statuses = Purchase.distinct.pluck(:status).sort!
    @other_attributes = %w[classpass close_to_expiry fixed main_purchase package_not_trial remind_to_renew rider sunsetted sunset_passed trial unlimited unpaid
                           written_off]
    @months = ['All'] + months_logged
  end

  def handle_sort
    case session[:sort_option]
    when 'client_dop', 'dop', 'expiry_date'
      sort_on_database
    when 'classes_remain'
      sort_on_object
    end
  end

  def sort_on_database
    @purchases = @purchases.send("order_by_#{session[:sort_option]}")
  end

  def sort_on_object
    @purchases = @purchases.package_started_not_expired.select(&:fixed_package?).to_a.sort_by do |p|
      p.attendances_remain(provisional: true, unlimited_text: false)
    end
    # restore to ActiveRecord and recover order.
    ids = @purchases.map(&:id)
    # @purchases_all_pages = Purchase.recover_order(ids)
    @purchases = Purchase.recover_order(ids)
    # @purchases = @purchases_all_pages.page params[:page]
    # @purchases = Purchase.where(id: @purchases.map(&:id)).page params[:page]
    # 'where' method does not retain the order of the items searched for, hence the more complicated approach
    # Detailed explanation in comments under 'recover_order' scope
  end

  def prepare_items_for_dropdowns
    # mapping now done by form.collection_select in view
    # @clients = Client.order_by_first_name.map { |c| [c.name, c.id] }
    @clients = Client.order_by_first_name
    @selected_client_index = (@clients.index(@clients.first_name_like(session[:select_client_name]).first) || 0) + 1
    # @products = Product.order_by_name_max_classes.includes(:workout_group, :current_price_objects)
    # params[:id] existence implies edit rather than new (without the discrepancy it would be problematic when editing a purchase if a product that was previously current had been retired)
    # preventing admin setting a new purchase with a rider product (which would not be associated with a main purchase). On edit this is more complicated, becasue it would be reasonable for example admin to add a note to a rider purchase
    @products = params[:id] ? Product.order_by_name_max_classes : Product.current.not_rider.order_by_name_max_classes
    @payment_methods = Setting.payment_methods
    # @renewal_discounts = Discount.with_rationale_at('renewal, @purchase.dop || Time.zone.now)
    # @renewal_discounts = [@discount_none] + Discount.with_rationale_at('Renewal', @purchase.dop || Time.zone.now)
    # @status_discounts = [@discount_none] + Discount.with_rationale_at('Status', @purchase.dop || Time.zone.now)
    # @oneoff_discounts = [@discount_none] + Discount.with_rationale_at('Oneoff', @purchase.dop || Time.zone.now)
    # @commercial_discounts = [@discount_none] + Discount.with_rationale_at('Commercial', @purchase.dop || Time.zone.now)
    # @discretion_discounts = [@discount_none] + Discount.with_rationale_at('Discretion', @purchase.dop || Time.zone.now)
    # dynamically set instance variables with instance_variable_set method
    @discount_none = Discount.joins(:discount_reason).where(discount_reasons: { rationale: 'Base' }).first
    discount_types = %w[renewal status commercial discretion oneoff]
    discount_types.each do |discount_type|
       instance_variable_set("@#{discount_type}_discounts", [@discount_none] + Discount.with_rationale_at(discount_type.capitalize, @purchase.dop || Time.zone.now))
       instance_variable_set("@selected_#{discount_type}_discount", @purchase.discounts.joins(:discount_reason).where(discount_reason: {rationale: discount_type.capitalize})&.first&.id)
    end
    # @selected_discount_renewal = @purchase.discounts.joins(:discount_reason).where(discount_reason: {rationale:'Renewal'})&.first&.id
  end

  def params_filter_list
    [:workout_group, :statuses, :search_name, :purchases_period] \
    + %i[classpass close_to_expiry fixed main_purchase package_not_trial remind_to_renew rider sunsetted sunset_passed trial unlimited unpaid written_off]
  end

  # ['workout_group_filter',...'sunsetted_filter',...:search_name]
  def session_filter_list
    params_filter_list.map { |i| [:search_name, :purchases_period].include?(i) ? i : "filter_#{i}" }
  end

  def post_purchase_processing
    update_purchase_status([@purchase])
    # return if @purchase.dropin? || !@purchase.workout_group.renewable?
    return if @purchase.dropin? || !@purchase.workout_group.requires_account?

    client = @purchase.client
    # setup account which returns some flashes as an array of type/message arrays
    Account.setup_for(client).each { |item| flash_message(*item) } if client.account.nil?
    # use splat to turn array returned into separate arguments
    # flash_message(*Whatsapp.new(whatsapp_params('new_purchase')).manage_messaging)
    flash_message(*TwilioMessage.new(twilio_message_params).manage)
  end

  # https://stackoverflow.com/questions/5750770/conditional-key-value-in-a-ruby-hash
  # def whatsapp_params(message_type)
  #   { receiver: @purchase.client,
  #     message_type:,
  #     variable_contents: { first_name: @purchase.client.first_name } }
  # end
  def twilio_message_params
    { receiver: @purchase.client,
      message_type: 'new_purchase',
      content_sid: 'HXc853fb537240534dd076f0114dc44e17', # per Twilio Content Template Builder
      content_variables: { first_name: @purchase.client.first_name } }
  end

  def handle_pagination
    # when exporting data, want it all not just the page of pagination
    if params[:export_all]
      #  @purchases.page(params[:page]).per(100_000)
      @pagy, @purchases = pagy(@purchases, items: 100_000)
    else
      #  @purchases.page params[:page]
      @pagy, @purchases = pagy(@purchases, items: Setting.purchases_pagination)
    end
  end

  def handle_index_response
    respond_to do |format|
      format.html
      # Railscasts #362 Exporting Csv And Excel
      # https://www.youtube.com/watch?v=SelheZSdZj8
      format.csv { send_data @purchases.to_csv, filename: "purchases-#{Time.zone.today.strftime('%e %b %Y')}.csv" }
      # https://stackoverflow.com/questions/617055/setting-the-filename-for-a-downloaded-file-in-a-rails-application Grant Neufeld to add a bespoke filename
      format.xls { response.headers['Content-Disposition'] = "attachment; filename=\"purchases-#{Time.zone.today.strftime('%e %b %Y')}.xls\"" }
      format.turbo_stream
    end
  end

  def handle_show_response
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
end
