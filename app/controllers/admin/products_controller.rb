class Admin::ProductsController < Admin::BaseController
  skip_before_action :admin_account, only: %i[ payment ]
  before_action :junioradmin_account, only: %i[ payment ]
  before_action :set_product, only: %i[ show edit update destroy ]
  after_action -> { update_purchase_status([@purchases]) }, only: %i[ update ]
  def index
    @products = Product.order_by_name_max_classes
  end

  def show
    session[:product_purchased_period] = params[:product_purchased_period] || session[:product_purchased_period] || Date.today.beginning_of_month.strftime('%b %Y')
    start_date = Date.parse(session[:product_purchased_period]).strftime('%Y-%m-%d')
    end_date = Date.parse(session[:product_purchased_period]).end_of_month.strftime('%Y-%m-%d')
    @purchases = Purchase.by_product_date(@product.id, start_date, end_date)
    # @client_hash = {
    #   number: attendances.size,
    #   base_revenue: base_revenue,
    #   expiry_revenue: expiry_revenue,
    #   total_revenue: base_revenue + expiry_revenue
    # }
    @months = months_logged
    # @prices = @product.prices.sort_by { |p| [p.current? ? 0 : 1, -p.price] }
    @prices = @product.prices.order_by_current_price
    respond_to do |format|
      format.html {}
      format.js {render 'show.js.erb'}
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
        flash[:success] = "Product was successfully created"
      else
        @workout_groups = WorkoutGroup.all.map { |wg| [wg.name, wg.id] }
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @product.update(product_params)
        @purchases = @product.purchases
        redirect_to admin_products_path
        flash[:success] = "Product was successfully updated"
      else
        @workout_groups = WorkoutGroup.all.map { |wg| [wg.name, wg.id] }
        render :edit, status: :unprocessable_entity
        end
  end

  def destroy
    @product.destroy
      redirect_to admin_products_path
      flash[:success] = "Product was successfully deleted"
  end

  def payment
    # [{"wg_name"=>"Space",.."price"=>500,.."name"=>"Space UC:1W power"}, {...}, {...} ...]
    #@base_payment = WorkoutGroup.products_hash[params[:selected_product].to_i]['price']
    # @products_hash = WorkoutGroup.products_hash
    # @base_payment = @products_hash[@products_hash.index {|p| p['name']==params[:selected_product]}]['price']
    @base_payment = Price.find(params[:selected_price]).price
    render 'payment.js.erb'
  end

  # def payment
  #   if params[:selected_product_name].blank?
  #     @product_types = Product.all.map { |p| [p.name, p.id] }
  #     @product_names = Product.find(params[:selected_product_type]).prices.map { |p| [p.name, p.id] }
  #     render 'namedropdowns.js.erb'
  #   else
  #   @base_payment = Price.find(params[:selected_product_name]).price
  #   render 'payment.js.erb'
  #   end
  # end

  private
    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:max_classes, :validity_length, :validity_unit, :workout_group_id)
    end
end
