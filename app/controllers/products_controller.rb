class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]

  def index
    @products = Product.all
  end

  def show
    session[:product_purchased_period] = params[:product_purchased_period] || session[:product_purchased_period] || Date.today.beginning_of_month.strftime('%b %Y')
    start_date = Date.parse(session[:product_purchased_period]).strftime('%Y-%m-%d')
    end_date = Date.parse(session[:product_purchased_period]).end_of_month.strftime('%Y-%m-%d')
    @purchases = Product.by_purchase_date(@product.id, start_date, end_date)
    # @client_hash = {
    #   number: attendances.size,
    #   base_revenue: base_revenue,
    #   expiry_revenue: expiry_revenue,
    #   total_revenue: base_revenue + expiry_revenue
    # }
    @months = months_logged
    @prices = @product.prices.sort_by { |p| p.date_from }.reverse!
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
        redirect_to products_path
        flash[:success] = "Product was successfully created"
      else
        @workout_groups = WorkoutGroup.all.map { |wg| [wg.name, wg.id] }
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @product.update(product_params)
        redirect_to products_path
        flash[:success] = "Product was successfully updated"
      else
        @workout_groups = WorkoutGroup.all.map { |wg| [wg.name, wg.id] }
        render :edit, status: :unprocessable_entity
        end
  end

  def destroy
    @product.destroy
      redirect_to products_path
      flash[:success] = "Product was successfully deleted"
  end

  private
    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:max_classes, :validity_length, :validity_unit, :workout_group_id)
    end
end
