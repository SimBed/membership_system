class Admin::PricesController < Admin::BaseController
  before_action :set_price, only: [:edit, :update, :destroy]
  # before_action :sanitize_params, only: [:create, :update]

  def new
    @price = Price.new
    @product = Product.find(params[:product_id])
    # @base_price = @product.prices.base&.first&.price || 0
    session[:pre_oct22_price] = false
  end

  def create
    @price = Price.new(price_params)

    if @price.save
      redirect_to admin_product_path(Product.find(price_params[:product_id]))
      flash[:success] = t('.success')
    else
      @product = Product.find(price_params[:product_id])
      # @base_price = @product.prices.base&.first&.price || 0
      session[:pre_oct22_price] = false
      # render "admin/prices/new?product_id=#{price_params[:product_id]}", status: :unprocessable_entity
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @base_price = @price.base_price || 0
    # @discounted_price = @price.discounted_price || 0
    @pre_oct22_price = @price.pre_oct22_price?
    # helpful to have this info stored on the browser, available to javascript
    session[:pre_oct22_price] = @pre_oct22_price
  end

  def update
    if @price.update(price_params)
      redirect_to admin_product_path(Product.find(price_params[:product_id]))
      flash[:success] = t('.success')
    else
      # @base_price = @price.base_price || 0
      # @discounted_price = @price.discounted_price || 0
      @pre_oct22_price = @price.pre_oct22_price?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product = @price.product
    @price.destroy
    redirect_to admin_product_path(@product)
    flash[:success] = t('.success')
  end

  private

  def set_price
    @price = Price.find(params[:id])
  end

  def price_params
    # the update method (and therefore the price_params method) is used through a form but also clicking on a link on the products show page within the prices listing
    return {date_until: Time.zone.now.to_date.yesterday, product_id: params[:product_id] } if params[:current].present? && params[:current] == 'false'
    return {date_until: 100.years.from_now, product_id: params[:product_id] } if params[:current].present? && params[:current] == 'true'

    params.require(:price).permit(:price, :date_from, :date_until, :product_id)
  end

  # def sanitize_params
  #   params[:price][:price] =  nil unless params[:price][:base]
  # end
end
