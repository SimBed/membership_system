class Admin::PurchasesController < Admin::BaseController
  before_action :initialize_sort, only: :index
  before_action :set_purchase, only: [:show, :edit, :update, :destroy]
  before_action :sanitize_params, only: [:create, :update]
  # https://stackoverflow.com/questions/30221810/rails-pass-params-arguments-to-activerecord-callback-function
  # parameter is an array to deal with the situation where eg a wkclass is deleted and multiple purchases need updating
  # this approach is no good as the callback should be after a successful create not a failed create
  # after_action -> { update_purchase_status([@purchase]) }, only: [:create, :update]

  def index
    # obsolete now - optimised by sorting at databse
    # convoluted but seems ok way to sort by date descending when date is part of a multiple parameter sort
    # @purchases = Purchase.all.sort_by { |p| [p.client.name, -p.dop&.to_time.to_i] }
    @purchases = Purchase.includes(:attendances, :product, :freezes, :adjustments, :client).all
    handle_search_name if session[:search_name].present?
    handle_search
    @workout_group = WorkoutGroup.distinct.pluck(:name).sort!
    @status = ['expired', 'frozen', 'not started', 'ongoing']
    @other_attributes = ['not invoiced']
    case session[:sort_option]
    when 'client_dop', 'dop'
      @purchases = @purchases.send("order_by_#{session[:sort_option]}").page params[:page]
    when 'expiry'
      @purchases = @purchases.with_package.started.not_expired.order_by_expiry_date.page params[:page]
    when 'classes_remain'
      @purchases = @purchases.with_package.started.not_expired.to_a.sort_by do |p|
        p.attendances_remain(provisional: true, unlimited_text: false)
      end
      # where does not retain the order of the items searched for, hence the more complicated approach below
      # @purchases = Purchase.where(id: @purchases.map(&:id)).page params[:page]
      ids = @purchases.map(&:id)
      # raw SQL in Active Record functions will give an error to guard against SQL injection
      # in the case where the raw SQl contains user input i.e. a params value
      # the error can be everriden by converting the raw SQL string literals to an Arel::Nodes::SqlLiteral object.
      # there is no user input in the converted Arel object, so this is OK
      # 'id:: text' is equivalent to 'CAST (id AS TEXT)' see https://www.postgresqltutorial.com/postgresql-cast/
      # position is a Postgresql string function, see https://www.postgresqltutorial.com/postgresql-position/
      @purchases = Purchase.where(id: ids)
                           .order(Arel.sql("POSITION(id::TEXT IN '#{ids.join(',')}')"))
                           .page params[:page]
    end

    respond_to do |format|
      format.html
      format.js { render 'index.js.erb' }
    end
  end

  def show
    @attendances = @purchase.attendances.sort_by { |a| -a.start_time.to_i }
  end

  def new
    @purchase = Purchase.new
    # mapping now done by form.collection_select in view
    # @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    @clients = Client.order_by_name
    @product_names = Product.order_by_name_max_classes
    @payment_methods = Rails.application.config_for(:constants)['payment_methods']
  end

  def edit
    @clients = Client.order_by_name
    @product_names = Product.order_by_name_max_classes
    @payment_methods = Rails.application.config_for(:constants)['payment_methods']
  end

  def create
    @purchase = Purchase.new(purchase_params)
    if @purchase.save
      # equivalent to redirect_to admin_purchase_path @purchase
      redirect_to [:admin, @purchase]
      flash[:success] = 'Purchase was successfully created'
      post_purchase_processing
    else
      @clients = Client.order_by_name
      @product_names = Product.order_by_name_max_classes
      @payment_methods = Rails.application.config_for(:constants)['payment_methods']
      render :new, status: :unprocessable_entity
    end
    # send_sms
    # send_whatsapp(@purchase.payment)
  end

  def update
    if @purchase.update(purchase_params)
      redirect_to [:admin, @purchase]
      flash[:success] = 'Purchase was successfully updated'
      update_purchase_status([@purchase])
    else
      @clients = Client.order_by_name.map { |c| [c.name, c.id] }
      @product_names = Product.order_by_name_max_classes
      @payment_methods = Rails.application.config_for(:constants)['payment_methods']
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase.destroy
    redirect_to admin_purchases_path
    flash[:success] = 'Purchase was successfully deleted'
  end

  def clear_filters
    # * is splat operator used to turn array into an argument list
    # https://ruby-doc.org/core-2.0.0/doc/syntax/calling_methods_rdoc.html#label-Array+to+Arguments+Conversion
    clear_session(*session_filter_list)
    redirect_to admin_purchases_path
  end

  # store the filter_form params in sessions
  def filter
    # see application_helper
    clear_session(*session_filter_list)
    session[:search_name] = params[:search_name]
    # e.g. session[:filter_status] = params[:status]
    (params_filter_list - [:search_name]).each do |item|
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

    # def sanitize_params
    #   params[:purchase][:invoice] = nil if params[:purchase][:invoice] == ''
    #   params[:purchase][:note] = nil if params[:purchase][:note] == ''
    #   params[:purchase][:fitternity_id]=Fitternity.ongoing.first&.id if params[:purchase][:payment_mode] == 'Fitternity'
    #   params[:purchase][:product_id] = nil if params[:purchase][:product_id].blank?
    # end

    def sanitize_params
      params.tap do |params|
        params[:purchase][:invoice] = nil if params.dig(:purchase, :invoice) == ''
        params[:purchase][:note] = nil if params.dig(:purchase, :note) == ''
        params[:purchase][:fitternity_id] = Fitternity.ongoing.first&.id if params[:purchase][:payment_mode] == 'Fitternity'
        params[:purchase][:product_id] = nil if params.dig(:purchase, :product_id).blank?
      end
    end

    def initialize_sort
      session[:sort_option] = params[:sort_option] || session[:sort_option] || 'client_dop'
    end

    def handle_search_name
      @purchases = @purchases.client_name_like(session[:search_name])
    end

    def handle_search
      if session[:filter_workout_group].present?
        @purchases = @purchases.with_workout_group(session[:filter_workout_group])
      end
      @purchases = @purchases.with_package.uninvoiced.requires_invoice if session[:filter_invoice].present?
      @purchases = @purchases.with_package if session[:filter_package].present?
      @purchases = @purchases.unpaid if session[:filter_unpaid].present?
      @purchases = @purchases.classpass if session[:filter_classpass].present?
      @purchases = @purchases.with_statuses(session[:filter_status]) if session[:filter_status].present?
      @purchases = @purchases.started.not_expired.select(&:close_to_expiry?) if session[:filter_close_to_expiry].present?
      # HACK: convert back to ActiveRecord for the order_by scopes of the index method, which will fail on an Array
      @purchases = Purchase.where(id: @purchases.map(&:id)) if @purchases.is_a?(Array)
    end

    # filtering_params(params).each do |key, value|
    #   @products = @products.public_send("filter_by_#{key}", value) if value.present?
    # end

    # The params names from filter_form.html.erb
    def params_filter_list
      [:workout_group, :status, :invoice, :package, :close_to_expiry,
       :unpaid, :classpass, :search_name]
    end

    # ['workout_group_filter',...'invoice_filter',...:search_name]
    def session_filter_list
      params_filter_list.map { |i| i == :search_name ? i : "filter_#{i}" }
    end

    def post_purchase_processing
      update_purchase_status([@purchase])
      whatsapp_recipients = [Rails.configuration.twilio[:me],
                             Rails.configuration.twilio[:boss]]
      unless @purchase.product.dropin?
        if @purchase.client.account.nil?
          #setup_account_for_new_client
          whatsapp_recipients.each do |recipient|
             #send_new_account_whatsapp(recipient)
             #send_new_purchase_whatsapp(recipient)
             #send_temp_email_confirm_whatsapp(recipient)
          end
        else
          whatsapp_recipients.each do |recipient|
             #send_new_purchase_whatsapp(recipient)
          end
        end
      end
    end

    def setup_account_for_new_client
      @account_holder = @purchase.client
      @password = Account.password_wizard(6)
      @account = Account.new(
         {password: @password, password_confirmation: @password,
          activated: true, ac_type: 'client', email: @account_holder.email}
          )
          if @account.save
            @account_holder.update(account_id: @account.id)
            flash[:success] = "account was successfully created"
          else
            flash[:warning] = "account was not created"
          end
    end

    def send_new_account_whatsapp(to)
      whatsapp_params = {to: to,
                         message_type: 'new_account',
                         variable_contents: { password: @password } }
      Whatsapp.new(whatsapp_params).send_whatsapp

      flash[:warning] = 'whatsapp was sent'
    end

    def send_new_purchase_whatsapp(to)
      whatsapp_params = {to: to,
                         message_type: 'new_purchase' }
      Whatsapp.new(whatsapp_params).send_whatsapp

      flash[:warning] = 'whatsapp was sent'
    end

    def send_temp_email_confirm_whatsapp(to)
      whatsapp_params = {to: to,
                         message_type: 'temp_email_confirm',
                         variable_contents: { email: @purchase.client.email } }
      Whatsapp.new(whatsapp_params).send_whatsapp
      flash[:warning] = 'whatsapp was sent'
    end
end
