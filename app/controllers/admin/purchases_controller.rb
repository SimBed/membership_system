class Admin::PurchasesController < Admin::BaseController
  include ApplyDiscount
  # reinclude once refactoring done, then replace dop = DateTime.new.. code in dop_change
  # include ParamsDateConstructor  
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :initialize_sort, only: :index
  before_action :set_purchase, only: [:show, :edit, :update, :destroy, :expire]
  before_action :sanitize_params, only: [:create, :update]
  # this should be a callback on Purchase model not a filter
  # before_action :already_had_trial?, only: [:create, :update]
  # before_action :changing_main_purchase_product?, only: :update
  # before_action :changing_main_purchase_name?, only: :update
  # before_action :changing_rider?, only: :update
  # https://stackoverflow.com/questions/30221810/rails-pass-params-arguments-to-activerecord-callback-function
  # parameter is an array to deal with the situation where eg a wkclass is deleted and multiple purchases need updating
  # this approach is no good as the callback should be after a successful create not a failed create
  # after_action -> { update_purchase_status([@purchase]) }, only: [:create, :update]

  def index
    # @purchases = Purchase.includes(:attendances, :product, :freezes, :adjustments, :client)
    # associations referrred to in view - attendances, product in start_to_expiry method, client directly in purchase.client.name
    @purchases = Purchase.includes(:attendances, :freezes, :adjustments, :penalties, :client, product: [:workout_group])
    @superadmin = logged_in_as?('superadmin')
    handle_search
    handle_filter
    handle_period
    handle_charting if @superadmin
    # Purchase.includes(:attendances, :product, :client).sum(:payment) duplicates payments because includes becomes single query joins in this situation
    # financial summary for superadmin only - don't want to risk unneccessary calc slowing down response for admin
    # much slower if unneccessarily done after sort
    # want the the total pages sum (not just the current page sum)
    # https://stackoverflow.com/questions/5483407/subqueries-in-activerecord - jan 3, 2012
    # this appeared to work but in some situations (i couldn't resolve fails with)
    # ActiveRecord::StatementInvalid Exception: PG::SyntaxError: ERROR:  subquery has too many columns
    # so reverted to previous less efficent 2 query approach
    # @purchases_all_pages_sum = Purchase.where("id IN (#{@purchases.select(:id).to_sql})").sum(:payment) if logged_in_as?('superadmin')
    @purchases_all_pages_sum = Purchase.where(id: @purchases.pluck(:id)).sum(:charge) if logged_in_as?('admin', 'superadmin')
    handle_sort
    prepare_items_for_filters
    handle_pagination
    handle_index_response
  end

  def show
    @discounts = @purchase.discounts
    @attendances_no_amnesty = @purchase.attendances.no_amnesty.merge(Attendance.order_by_date)
    @attendances_amnesty = @purchase.attendances.amnesty.merge(Attendance.order_by_date)
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

  def discount
    dop = DateTime.new(params[:dop_1i].to_i,
    params[:dop_2i].to_i,
    params[:dop_3i].to_i)
    renewal_discount = Discount.find(params[:renewal_discount_id])
    status_discount = Discount.find(params[:status_discount_id])
    commercial_discount = Discount.find(params[:commercial_discount_id])
    discretion_discount = Discount.find(params[:discretion_discount_id])
    oneoff_discount = Discount.find(params[:oneoff_discount_id])
    base_price = Price.base_at(Time.zone.now).find_by(product_id: params[:product_id])
    payment_after_discount = apply_discount(base_price, renewal_discount, status_discount, oneoff_discount, discretion_discount, commercial_discount)
    render json: { base_price_id: base_price&.id,
                   base_price_price: base_price&.price,
                   payment_after_discount: payment_after_discount }
  end

  def dop_change
    # dop = construct_date(params, 'dop')
    dop = DateTime.new(params[:dop_1i].to_i,
    params[:dop_2i].to_i,
    params[:dop_3i].to_i)
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

  private

  def discount_options(discount_type, date, discount_none)
    [discount_none] + Discount.with_rationale_at(discount_type.capitalize, date)
  end

  def create_rider
    rider_product = Product.where(rider: true).first
    rider_product_price = rider_product.base_price_at(Time.zone.now)
    @rider_purchase = @purchase.dup
    if @rider_purchase.update({ product_id: rider_product.id,
                                charge: 0,
                                payment_mode: 'Not applicable',
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

  # def changing_main_purchase_product?
  #   return false if params[:purchase][:product_id].blank?

  #   original_purchase_has_rider = @purchase.product.has_rider?
  #   new_product_has_rider = Product.find(params[:purchase][:product_id]).has_rider?
  #   return false if (original_purchase_has_rider && new_product_has_rider) || (!original_purchase_has_rider && !new_product_has_rider)

  #   flash[:warning] = "Purchase not updated. Can't change a purchase without a rider to one with a rider." if !original_purchase_has_rider && new_product_has_rider
  #   flash[:warning] = "Purchase not updated. Can't change a purchase with a rider to one without a rider." if original_purchase_has_rider && !new_product_has_rider
  #   redirect_to edit_purchase_path(@purchase)
  # end

  # def changing_main_purchase_name?
  #   original_purchase_has_rider = @purchase.rider_purchase.present?
  #   client_changed = @purchase.client_id != params[:purchase][:client_id].to_i

  #   return false unless client_changed && original_purchase_has_rider

  #   flash[:warning] = "Purchase not updated. Can't change client of a purchase with a rider."
  #   redirect_to edit_purchase_path(@purchase)
  # end

  # def changing_rider?
  #   return false if @purchase.main_purchase.nil?

  #   flash[:warning] = "Purchase not updated. Can't change details of a purchase that is a rider"
  #   redirect_to purchase_path(@purchase)
  # end

  def adjust_and_restart
    new_purchase = @purchase.dup
    new_purchase.update(status: 'not started' )
    flash_message :warning, t('.adjust_and_restart')
    redirect_to purchases_path
  end

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def purchase_params
    p = params.require(:purchase)
    .permit(:client_id, :product_id, :price_id, :charge, :dop, :note, :renewal_discount_id, :status_discount_id, :oneoff_discount_id,
    :commercial_discount_id, :discretion_discount_id, payment_attributes: [:dop, :amount, :payment_mode, :note])
    # temporarily retain payment_method in Purchase model
    p.merge!(payment_mode: params[:purchase][:payment_attributes][:payment_mode])  if params[:purchase][:payment_attributes]
    p
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
    #   if params[:adjust_restart] == '0'
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

  def handle_charting
    # HACK: for timezone issue with groupdata https://github.com/ankane/groupdate/issues/66
    Purchase.default_timezone = :utc
    # Would like to replace 'Purchase.where(id: @purchases.map(&:id))' with '@purchases' but without this hack @purchase_payments_for_chart gives strange results (doubling up on some purchases)...haven't resolved
    # Bullet.enable = false if Rails.env == 'development'
    @purchase_count_for_chart = Purchase.where(id: @purchases.map(&:id)).group_by_week(:dop).count
    @purchase_payments_for_chart = Purchase.where(id: @purchases.map(&:id)).group_by_week(:dop).sum(:charge)
    # Bullet.enable = true if Rails.env == 'development'
    Purchase.default_timezone = :local
  end  

  def prepare_items_for_filters
    @workout_group = WorkoutGroup.distinct.pluck(:name).sort!
    @statuses = Purchase.distinct.pluck(:status).sort!
    # ['expired', 'frozen', 'not started', 'ongoing']
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
    # @purchases = @purchases.send("order_by_#{session[:sort_option]}").page params[:page]
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
    flash_message(*Whatsapp.new(whatsapp_params('new_purchase')).manage_messaging)
  end

  # https://stackoverflow.com/questions/5750770/conditional-key-value-in-a-ruby-hash
  def whatsapp_params(message_type)
    { receiver: @purchase.client,
      message_type:,
      variable_contents: { first_name: @purchase.client.first_name } }
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
