class Admin::PurchasesController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :initialize_sort, only: :index
  before_action :set_purchase, only: [:show, :edit, :update, :destroy]
  before_action :sanitize_params, only: [:create, :update]
  # https://stackoverflow.com/questions/30221810/rails-pass-params-arguments-to-activerecord-callback-function
  # parameter is an array to deal with the situation where eg a wkclass is deleted and multiple purchases need updating
  # this approach is no good as the callback should be after a successful create not a failed create
  # after_action -> { update_purchase_status([@purchase]) }, only: [:create, :update]

  def index
    # @purchases = Purchase.includes(:attendances, :product, :freezes, :adjustments, :client)
    # associations referrred to in view - attendances, product in start_to_expiry method, client directly in purchase.client.name
    @purchases = Purchase.includes(:attendances, :product, :client)
    handle_search
    handle_filter
    handle_period
    # Purchase.includes(:attendances, :product, :client).sum(:payment) duplicates payments because includes becomes single query joins in this situation
    # financial summary for superadmin only - don't want to risk unneccessary calc slowing down response for admin
    # much slower if unneccessarily done after sort
    # want the the total pages sum (not just the current page sum)
    # https://stackoverflow.com/questions/5483407/subqueries-in-activerecord - jan 3, 2012
    @purchases_all_pages_sum = Purchase.where("id IN (#{@purchases.select(:id).to_sql})").sum(:payment) if logged_in_as?('superadmin')
    # @purchases_all_pages_sum = Purchase.where(id: @purchases.pluck(:id)).sum(:payment) if logged_in_as?('superadmin')
    handle_sort
    prepare_items_for_filters
    respond_to do |format|
      format.html
      format.js { render 'index.js.erb' }
    end
  end

  def show
    # @attendances = @purchase.attendances.sort_by { |a| -a.start_time.to_i }
    # @attendances = Attendance.joins(:purchase, :wkclass).where(purchase: @purchase).order(start_time: :desc)
    @attendances_no_amnesty = @purchase.attendances.no_amnesty.merge(Attendance.order_by_date)
    @attendances_amnesty = @purchase.attendances.amnesty.merge(Attendance.order_by_date)
  end

  def new
    @purchase = Purchase.new
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
  end

  def create
    @purchase = Purchase.new(purchase_params)
    if @purchase.save
      # equivalent to redirect_to admin_purchase_path @purchase
      redirect_to [:admin, @purchase]
      flash_message :success, t('.success')
      # flash[:success] = t('.success')
      post_purchase_processing
    else
      prepare_items_for_dropdowns
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @purchase.update(purchase_params)
      redirect_to [:admin, @purchase]
      flash_message :success, t('.success')
      update_purchase_status([@purchase])
    else
      prepare_items_for_dropdowns
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase.destroy
    redirect_to admin_purchases_path
    flash_message :success, t('.success')
  end

  def clear_filters
    # *splat operator is used to turn array into an argument list
    # https://ruby-doc.org/core-2.0.0/doc/syntax/calling_methods_rdoc.html#label-Array+to+Arguments+Conversion
    clear_session(*session_filter_list)
    redirect_to admin_purchases_path
  end

  def filter
    clear_session(*session_filter_list)
    session[:search_name] = params[:search_name]
    session[:purchases_period] = params[:purchases_period]
    (params_filter_list - [:search_name, :purchases_period]).each do |item|
      session["filter_#{item}".to_sym] = params[item]
    end
    redirect_to admin_purchases_path
  end

  private

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def purchase_params
    params.require(:purchase)
          .permit(:client_id, :product_id, :price_id, :payment, :dop, :payment_mode,
                  :invoice, :note, :adjust_restart, :ar_payment, :ar_date, :fitternity_id)
  end

  def sanitize_params
    nillify_when_blank(params[:purchase], :invoice, :note)
    params[:purchase].tap do |params|
      params[:fitternity_id] = Fitternity.ongoing.first&.id if params[:payment_mode] == 'Fitternity'
      # params[:product_id] = nil if params[:product_id].blank?
    end
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
    %w[uninvoiced package close_to_expiry unpaid classpass trial fixed].each do |key|
      @purchases = @purchases.send(key) if session["filter_#{key}"].present?
    end
    %w[workout_group statuses].each do |key|
      @purchases = @purchases.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
    end
    # some scopes will return an array (not an ActiveRecord) eg close_to_expiry so
    # HACK: convert back to ActiveRecord for the order_by scopes of the index method, which will fail on an Array
    @purchases = Purchase.where(id: @purchases.map(&:id)) if @purchases.is_a?(Array)
  end

  def handle_period
    return unless session[:purchases_period].present? && session[:purchases_period] != 'All'

    @purchases = @purchases.during(month_period(session[:purchases_period]))
  end

  def prepare_items_for_filters
    @workout_group = WorkoutGroup.distinct.pluck(:name).sort!
    @statuses = Purchase.distinct.pluck(:status).sort!
    # ['expired', 'frozen', 'not started', 'ongoing']
    @other_attributes = %w[classpass close_to_expiry fixed package trial uninvoiced unpaid]
    @months = months_logged + ['All']
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
    @purchases = @purchases.send("order_by_#{session[:sort_option]}").page params[:page]
  end

  def sort_on_object
    @purchases = @purchases.package_started_not_expired.select(&:fixed_package?).to_a.sort_by do |p|
      p.attendances_remain(provisional: true, unlimited_text: false)
    end
    # restore to ActiveRecord and recover order.
    ids = @purchases.map(&:id)
    @purchases_all_pages = Purchase.recover_order(ids)
    @purchases = @purchases_all_pages.page params[:page]
    # @purchases = Purchase.where(id: @purchases.map(&:id)).page params[:page]
    # 'where' method does not retain the order of the items searched for, hence the more complicated approach
    # Detailed explanation in comments under 'recover_order' scope
  end

  def prepare_items_for_dropdowns
    # mapping now done by form.collection_select in view
    # @clients = Client.order_by_first_name.map { |c| [c.name, c.id] }
    @clients = Client.order_by_first_name
    @product_names = Product.order_by_name_max_classes
    @payment_methods = Rails.application.config_for(:constants)['payment_methods']
  end

  def params_filter_list
    [:workout_group, :statuses, :uninvoiced, :package, :close_to_expiry,
     :unpaid, :classpass, :trial, :fixed, :search_name, :purchases_period]
  end

  # ['workout_group_filter',...'invoice_filter',...:search_name]
  def session_filter_list
    params_filter_list.map { |i| [:search_name, :purchases_period].include?(i) ? i : "filter_#{i}" }
  end

  def post_purchase_processing
    update_purchase_status([@purchase])
    return if @purchase.dropin? || @purchase.pt?

    if @purchase.client.account.nil?
      setup_account_for_new_client
    end
    manage_messaging('new_purchase')
  end

  # whatsapp_recipient_numbers = [Rails.configuration.twilio[:me], Rails.configuration.twilio[:boss]]
  # whatsapp_recipient_numbers.each do |recipient|
  #   send_new_account_whatsapp(recipient)
  #   send_new_purchase_whatsapp(recipient)
  #   # send_temp_email_confirm_whatsapp(recipient)
  # end

  def setup_account_for_new_client
    @account_holder = @purchase.client
    @password = Account.password_wizard(6)
    @account = Account.new(
      { password: @password, password_confirmation: @password,
        activated: true, ac_type: 'client', email: @account_holder.email }
    )
    if @account.save
      @account_holder.update(account_id: @account.id)
      flash_message :success, t('admin.accounts.create.success')
      # flash[:success] = I18n.t 'admin.accounts.create.success'
      # flash[:success] = 'Account was successfully created'
      manage_messaging('new_account')
    else
      flash_message :warning, t('admin.accounts.create.warning')
      # flash[:warning] = I18n.t 'admin.accounts.create.warning'
      # flash[:warning] = 'Account was not created'
    end
  end

  def manage_messaging(message_type)
    recipient_number = @purchase.client.whatsapp_messaging_number
    if recipient_number.nil?
      flash_message :warning, "Client has no contact number. #{message_type == 'new_account'  ? 'Account login' : 'Purchase'} details not sent"
    else
      return unless white_list_whatsapp_receivers
      send "send_#{message_type}_whatsapp" , recipient_number
      flash_message :warning, "#{message_type == 'new_account'  ? 'Account login' : 'New  purchase'} message sent to #{recipient_number}"
    end
  end

  def send_new_account_whatsapp(to)
    return unless white_list_whatsapp_receivers
    whatsapp_params = { to: to,
                        message_type: 'new_account',
                        variable_contents: { password: @password } }
    Whatsapp.new(whatsapp_params).send_whatsapp
  end

  def send_new_purchase_whatsapp(to)
    return unless white_list_whatsapp_receivers
    whatsapp_params = { to: to,
                        message_type: 'new_purchase' }
    Whatsapp.new(whatsapp_params).send_whatsapp
  end

  # def send_temp_email_confirm_whatsapp(to)
  #   whatsapp_params = { to: to,
  #                       message_type: 'temp_email_confirm',
  #                       variable_contents: { email: @purchase.client.email } }
  #   Whatsapp.new(whatsapp_params).send_whatsapp
  # end

end
