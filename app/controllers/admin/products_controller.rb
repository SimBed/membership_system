class Admin::ProductsController < Admin::BaseController
  skip_before_action :admin_account, only: [:payment, :index]
  before_action :junioradmin_account, only: [:payment, :index]
  before_action :initialize_sort, only: :index
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  # don't do as callback because only on successful update not failed update
  # after_action -> { update_purchase_status(@purchases) }, only: [:update]

  def index
    handle_sort
    @products = @products.space_group if logged_in_as?('junioradmin')
    ongoing_purchases = Purchase.not_fully_expired
    @product_ongoing_count = {}
    @product_total_count = {}
    @products.each do |product|
      @product_ongoing_count[product.name.to_sym] = ongoing_purchases.where(product_id: product.id).size
    end
    @products.each do |product|
      @product_total_count[product.name.to_sym] = Purchase.where(product_id: product.id).size
    end
    respond_to do |format|
      format.html
      format.csv { send_data @products.to_csv }
    end
  end

  def show
    set_period
    @purchases = Purchase.by_product_date(@product.id, session[:product_period])
    @months = months_logged
    # messy because of the Price default sope which is useful for the grouped_collection_select in the purchase form (prices dropdown)
    @prices = @product.prices.unscope(:order).order_by_current_discount
    respond_to do |format|
      format.html
      format.js { render 'show.js.erb' }
    end
  end

  def new
    @product = Product.new
    prepare_items_for_dropdowns
  end

  def edit
    prepare_items_for_dropdowns
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_products_path
      flash[:success] = t('.success')
    else
      prepare_items_for_dropdowns
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      @purchases = @product.purchases
      redirect_to admin_products_path
      flash[:success] = t('.success')
      update_purchase_status(@purchases)
    else
      prepare_items_for_dropdowns
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to admin_products_path
    flash[:success] = t('.success')
  end

  def payment
    @payment_for_price = Price.find(params[:selected_price]).discounted_price
    # @base_payment = Price.find(params[:selected_price]).price
    # https://stackoverflow.com/questions/36228873/ruby-how-to-convert-a-string-to-boolean
    # @fitternity = ActiveModel::Type::Boolean.new.cast(params[:fitternity])
    render 'payment.js.erb'
  end

  private

  def initialize_sort
    session[:product_sort_option] = params[:product_sort_option] || session[:product_sort_option] || 'product_name'
  end  

  def handle_sort
    # reformat
    case session[:product_sort_option]
    when 'product_name'
      @products = Product.order_by_name_max_classes
    when 'total_count'
      @products = Product.order_by_total_count
    when 'ongoing_count'
      @products = Product.order_by_ongoing_count
    else
      # just for now
      @products = Product.order_by_name_max_classes
    end
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

  def set_product
    @product = Product.find(params[:id])
  end

  def set_period
    period = params[:product_period] || session[:product_period] || Time.zone.today.beginning_of_month.strftime('%b %Y')
    session[:product_period] = (Date.parse(period).beginning_of_month..Date.parse(period).end_of_month.end_of_day)
  end

  def prepare_items_for_dropdowns
    @workout_groups = WorkoutGroup.all
    @validity_units = [['days', 'D'], ['weeks', 'W'], ['months', 'M']]
  end

  def product_params
    # the update method (and therefore the product_params method) is used through a form but also clicking on a link on the products page    
    return {sellonline: params[:sellonline] } if params[:sellonline].present?

    params.require(:product).permit(:max_classes, :validity_length, :validity_unit, :workout_group_id, :sellonline)
  end
end
