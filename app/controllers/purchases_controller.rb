class PurchasesController < ApplicationController
  before_action :initialize_sort, only: :index
  before_action :set_purchase, only: %i[ show edit update destroy ]

  def index
    # obsolete now - optimised by sorting at databse
    # convoluted but seems ok way to sort by date descending when date is part of a multiple parameter sort
    #@purchases = Purchase.all.sort_by { |p| [p.client.name, -p.dop&.to_time.to_i] }
    @purchases = Purchase.all
    handle_search_name unless session[:search_name].blank?
    handle_search
    #@problems = @problems.send("order_by_#{session[:sort_option]}").paginate(page: params[:page], per_page: 10)
    @workout_group = WorkoutGroup.distinct.pluck(:name).sort!
    @status = %w[expired frozen not\ started ongoing]
    case session[:sort_option]
    when 'client_dop', 'dop'
      @purchases = @purchases.send("order_by_#{session[:sort_option]}").page params[:page]
    when 'expiry'
      @purchases = @purchases.to_a.sort_by { |p| p.days_to_expiry }
      @purchases = Purchase.where(id: @purchases.map(&:id)).page params[:page]
    when 'classes_remain'
      @purchases = @purchases.not_expired.to_a.sort_by { |p| p.attendances_remain_numeric }
      @purchases = Purchase.where(id: @purchases.map(&:id)).page params[:page]
    end

    # it is not critical that expired purchases are identifiable at database level. This will just improve efficiency as the number of purchases gets biggger over time.
    # For example, the form for adding a new attendance makes qualifying purchases available from a select box. It is inefficient
    # to have to run ruby code on the entire population of purchases to identify the non-expired purchases.
    # There are probably more appropriate ways of updating the purchase's status at database level, but running some code
    # here is inoccuous (negligibly slows down a non-speed-critical page) and means the database will be kept up to data intermittently which achieves the aim.
    expire_purchases
    respond_to do |format|
      format.html {}
      format.js {render 'index.js.erb'}
    end
  end

  def show
    @attendances = @purchase.attendances.sort_by { |a| -a.start_time.to_i }
  end

  def new
    @purchase = Purchase.new
    @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    # @products_hash = WorkoutGroup.products_hash
    # @product_names = @products_hash.map.with_index { |p, index| [Product.full_name(p['wg_name'], p['max_classes'], p['validity_length'], p['validity_unit'], p['price_name']), index]}
    @product_names = WorkoutGroup.products_hash.map { |p| p['name'] }
    @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
  end

  def edit
    @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    @product_names = WorkoutGroup.products_hash.map { |p| p['name'] }
    # as the product name is not an attribute of the purchase model, it is not automatically selected in the dropdown
    @product_name = Product.full_name(@purchase.product.workout_group.name, @purchase.product.max_classes, @purchase.product.validity_length, @purchase.product.validity_unit, @purchase.product.prices.where('price=?', @purchase.payment).first&.name)
    @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
  end

  def create
    @purchase = Purchase.new(purchase_params)
      if @purchase.save
        redirect_to @purchase
        flash[:success] = "Purchase was successfully created"
      else
        @clients = Client.order_by_name.map { |c| [c.name, c.id] }
        @product_names = WorkoutGroup.products_hash.map { |p| p['name'] }
        @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @purchase.update(purchase_params)
        redirect_to @purchase
        flash[:success] = "Purchase was successfully updated"
      else
        @clients = Client.order_by_name.map { |c| [c.name, c.id] }
        @product_names = WorkoutGroup.products_hash.map { |p| p['name'] }
        @product_name = Product.full_name(@purchase.product.workout_group.name, @purchase.product.max_classes, @purchase.product.validity_length, @purchase.product.validity_unit, @purchase.product.prices.where('price=?', @purchase.payment).first&.name) unless purchase_params[:product_id].nil?
        @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
        render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase.destroy
      redirect_to purchases_url
      flash[:success] = "Purchase was successfully deleted"
  end

  def clear_filters
    clear_session(:filter_workout_group, :filter_status, :search_name)
    redirect_to purchases_path
  end

  def filter
    # see application_helper
    clear_session(:filter_workout_group, :filter_status, :search_name)
    # Without the ors (||) the sessions would get set to nil when redirecting to purchases other than through the
    # filter form (e.g. by clicking purchases on the navbar) (as the params items are nil in these cases)
    session[:search_name] = params[:search_name] || session[:search_name]
    session[:filter_workout_group] = params[:workout_group] || session[:filter_workout_group]
    session[:filter_status] = params[:status] || session[:filter_status]
    redirect_to purchases_path
  end

  private

    def expire_purchases
      Purchase.not_expired.each do |p|
        p.update({expired: true}) if p.expired?
      end
    end

    def set_purchase
      @purchase = Purchase.find(params[:id])
    end

    def purchase_params
      pp = params.require(:purchase).permit(:client_id, :payment, :dop, :payment_mode, :invoice, :note, :adjust_restart, :ar_payment, :ar_date)
      pp[:fitternity_id] = Fitternity.ongoing.first&.id if params[:purchase][:payment_mode] == 'Fitternity'
      @products_hash = WorkoutGroup.products_hash
      # pp[:product_id] = @products_hash[params[:purchase][:products_hash_index].to_i]['product_id']
      if params[:purchase][:product_name].blank?
        pp[:product_id] = nil
      else
        pp[:product_id] = @products_hash[@products_hash.index {|p| p['name']==params[:purchase][:product_name]}]['product_id']
      end
      pp
    end

    def initialize_sort
      session[:sort_option] = params[:sort_option] || session[:sort_option] || 'client_dop'
    end

    def handle_search_name
      @purchases = @purchases.client_name_like(session[:search_name])
    end

    def handle_search
      @purchases = @purchases.with_workout_group(session[:filter_workout_group]) if session[:filter_workout_group].present?
      @purchases = @purchases.select { |p| session[:filter_status].include?(p.status) } if session[:filter_status].present?
      # hack to convert back to ActiveRecord for the order_by scopes of the index method, which will fail on an Array
      @purchases = Purchase.where(id: @purchases.map(&:id)) if @purchases.is_a?(Array)
    end

end
