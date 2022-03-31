class Admin::PurchasesController < Admin::BaseController
  before_action :initialize_sort, only: :index
  before_action :set_purchase, only: [:show, :edit, :update, :destroy]
  # https://stackoverflow.com/questions/30221810/rails-pass-params-arguments-to-activerecord-callback-function
  # parameter is an array to deal with the situation where eg a wkclass is deleted and multiple purchases need updating
  after_action -> { update_purchase_status([@purchase]) }, only: [:create, :update]

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
    pp = params.require(:purchase).permit(:client_id, :product_id, :price_id, :payment, :dop, :payment_mode,
                                          :invoice, :note, :adjust_restart, :ar_payment, :ar_date)
    pp[:invoice] = nil if pp[:invoice] == ''
    pp[:note] = nil if pp[:note] == ''
    pp[:fitternity_id] = Fitternity.ongoing.first&.id if params[:purchase][:payment_mode] == 'Fitternity'
    pp[:product_id] = nil if params[:purchase][:product_id].blank?
    pp
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
    @purchases = @purchases.uninvoiced.requires_invoice if session[:filter_invoice].present?
    @purchases = @purchases.with_package if session[:filter_package].present?
    @purchases = @purchases.unpaid if session[:filter_unpaid].present?
    @purchases = @purchases.classpass if session[:filter_classpass].present?
    @purchases = @purchases.with_statuses(session[:filter_status]) if session[:filter_status].present?
    @purchases = @purchases.started.not_expired.select(&:close_to_expiry?) if session[:filter_close_to_expiry].present?
    # HACK: to convert back to ActiveRecord for the order_by scopes of the index method, which will fail on an Array
    @purchases = Purchase.where(id: @purchases.map(&:id)) if @purchases.is_a?(Array)
  end

  # A list of the param names that can be used for filtering Purchases
  def params_filter_list
    [:workout_group, :status, :invoice, :package, :close_to_expiry,
     :unpaid, :classpass, :search_name]
  end

  def session_filter_list
    params_filter_list.map { |i| i == :search_name ? i : "filter_#{i}" }
  end

  def send_sms
    account_sid = Rails.configuration.twilio[:account_sid]
    auth_token = Rails.configuration.twilio[:auth_token]
    from = Rails.configuration.twilio[:number]
    to = Rails.configuration.twilio[:me]
    client = Twilio::REST::Client.new(account_sid, auth_token)

    client.messages.create(
      from: from,
      to: to,
      body: 'The Space - Product Purchase'
    )
  end

  def send_whatsapp(payment)
    account_sid = Rails.configuration.twilio[:account_sid]
    auth_token = Rails.configuration.twilio[:auth_token]
    from = Rails.configuration.twilio[:whatsapp_number]
    to = Rails.configuration.twilio[:me]
    client = Twilio::REST::Client.new(account_sid, auth_token)

    client.messages.create(
      from: "whatsapp:#{from}",
      to: "whatsapp:#{to}",
      body: "The Space - Product Purchase
         #{@purchase.name_with_dop}
         #{payment} Rs."
    )
  end
end
