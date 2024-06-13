class Admin::ProductsController < Admin::BaseController
  skip_before_action :admin_account, only: [:index, :filter, :clear_filters]
  before_action :junioradmin_account, only: [:index, :filter, :clear_filters]
  before_action :initialize_sort, only: :index
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  # don't do as callback because only on successful update not failed update
  # after_action -> { update_purchase_status(@purchases) }, only: [:update]

  def index
    @products = Product.all
    # @products_not_current = Product.not_current
    handle_filter
    handle_sort
    @workout_groups = WorkoutGroup.order_by_current
    # reinstate this once sorted out the sorting (sorting by price returns an array)
    # @products = @products.space_group if logged_in_as?('junioradmin')
    set_data
    handle_index_response
  end

  def show
    set_period
    @purchases = Purchase.by_product_date(@product.id, @period)
    # add all in due course
    # @months = ['All'] + months_logged
    @months = months_logged
    # NOTE: sort_by fails with booleans
    # NOTE: Date object cant directly be converted to integer for reverse ordering
    # https://stackoverflow.com/questions/4492557/convert-ruby-date-to-integer
    @prices = @product.prices.sort_by { |p| [p.current? ? 0 : 1, -p.date_from.to_time.to_i] }
  end

  def new
    @product = Product.new
    prepare_items_for_dropdowns
    @form_cancel_link = products_path
  end

  def edit
    prepare_items_for_dropdowns
    @form_cancel_link = products_path
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to products_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      @purchases = @product.purchases
      redirect_to products_path
      flash[:success] = t('.success')
      update_purchase_status(@purchases)
      update_sunset_date(@purchases)
    else
      prepare_items_for_dropdowns
      @form_cancel_link = products_path 
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path
    flash[:success] = t('.success')
  end

  def clear_filters
    clear_session(*session_filter_list)
    redirect_to products_path
  end

  def filter
    clear_session(*session_filter_list)
    params_filter_list.each do |item|
      session["filter_#{item}".to_sym] = params[item]
    end
    redirect_to products_path
  end

  private

  def initialize_sort
    session[:product_sort_option] = params[:product_sort_option] || session[:product_sort_option] || 'product_name'
  end

  def handle_filter
    %w[any_workout_group_of].each do |key|
      @products = @products.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
      # @products_not_current = @products_not_current.send(key, session["filter_#{key}"]) if session["filter_#{key}"].present?
    end
    %w[sell_online current not_current rider has_rider].each do |key|
      @products = @products.send(key) if session["filter_#{key}"].present?
      # @products_not_current = @products_not_current.send(key) if session["filter_#{key}"].present?
    end    
  end

  def handle_sort
    case session[:product_sort_option]
    when 'total_count', 'ongoing_count'
      # https://stackoverflow.com/questions/20014292/chain-an-additional-order-on-a-rails-activerecord-query 'using a subquery'. @products_current.order_by_total_count fails
      @products = Product.send("order_by_#{session[:product_sort_option]}").where(id: @products)
      # @products_not_current = Product.send("order_by_#{session[:product_sort_option]}").where(id: @products_not_current)
    when 'price'
      @products = @products.order_by_base_price
      # @products_not_current = @products_not_current.order_by_base_price
    else # includes 'product_name'
      # just for now
      # @products_current = @products_current.order_by_name_max_classes
      # @products_not_current = @products_not_current.order_by_name_max_classes
      @products = Product.order_by_name_max_classes.where(id: @products)
      # @products_not_current = Product.order_by_name_max_classes.where(id: @products_not_current)
    end
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def set_period
    default_month = Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:product_period] = params[:product_period] || session[:product_period] || default_month
    @period = month_period(session[:product_period])
  end

  def prepare_items_for_dropdowns
    @workout_groups = @product.new_record? ? WorkoutGroup.current.order_by_current : WorkoutGroup.order_by_current
    @validity_units = [%w[days D], %w[weeks W], %w[months M]]
    @colors = Setting.product_colors
  end

  def set_data
    ongoing_purchases = Purchase.not_fully_expired
    @products_data = {}
    # @product_ongoing_count = {}
    # @product_total_count = {}
    # @product_base_price = {}
    @products.each do |product|
      @products_data[product.id] =
       { ongoing_count: ongoing_purchases.where(product_id: product.id).size,
         total_count: Purchase.where(product_id: product.id).size,
         base_price: product.base_price_at(Time.zone.now)&.price }
      # @products_data[product.name(rider_show: true).to_sym] = { ongoing_count: ongoing_purchases.where(product_id: product.id).size,
      # total_count: Purchase.where(product_id: product.id).size,
      # base_price: product.base_price_at(Time.zone.now)&.price }
    end
  end

  def handle_index_response
    respond_to do |format|
      format.html
      format.csv { send_data @products.to_csv }
      format.turbo_stream
    end
  end

  def params_filter_list
    [:any_workout_group_of, :sell_online, :current, :not_current, :rider, :has_rider]
  end

  def session_filter_list
    params_filter_list.map { |i| "filter_#{i}" }
  end

  def product_params
    # the update method (and therefore the product_params method) is used through a form but also clicking on a link on the products page
    return { sellonline: params[:sellonline] } if params[:sellonline].present?
    return { current: params[:current] } if params[:current].present?

    params.require(:product).permit(:max_classes, :validity_length, :validity_unit, :color, :workout_group_id, :sellonline, :current, :not_current, :rider, :has_rider).reject do |_, v|
      v == 'none'
    end
  end


end
