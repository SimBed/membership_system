class Admin::ProductsController < Admin::BaseController
  skip_before_action :admin_account, only: [:payment]
  before_action :junioradmin_account, only: [:payment]
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  after_action -> { update_purchase_status(@purchases) }, only: [:update]

  def index
    @products = Product.order_by_name_max_classes
    respond_to do |format|
      format.html
      format.csv { send_data @products.to_csv }
    end
  end

  def show
    set_period
    @purchases = Purchase.by_product_date(@product.id, session[:product_period])
    @months = months_logged
    @prices = @product.prices.order_by_current_price
    respond_to do |format|
      format.html
      format.js { render 'show.js.erb' }
    end
  end

  def new
    @product = Product.new
    @workout_groups = WorkoutGroup.all.map { |wg| [wg.name, wg.id] }
  end

  def edit
    @workout_groups = WorkoutGroup.all.map { |wg| [wg.name, wg.id] }
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_products_path
      flash[:success] = t('.success')
    else
      @workout_groups = WorkoutGroup.all.map { |wg| [wg.name, wg.id] }
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      @purchases = @product.purchases
      redirect_to admin_products_path
      flash[:success] = t('.success')
    else
      @workout_groups = WorkoutGroup.all.map { |wg| [wg.name, wg.id] }
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to admin_products_path
    flash[:success] = t('.success')
  end

  def payment
    @base_payment = Price.find(params[:selected_price]).price
    # https://stackoverflow.com/questions/36228873/ruby-how-to-convert-a-string-to-boolean
    # @fitternity = ActiveModel::Type::Boolean.new.cast(params[:fitternity])
    render 'payment.js.erb'
  end

  private

  def set_period
    period = params[:product_period] || session[:product_period] || Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:product_period] = (Date.parse(period).beginning_of_month..Date.parse(period).end_of_month.end_of_day)
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:max_classes, :validity_length, :validity_unit, :workout_group_id)
  end
end
