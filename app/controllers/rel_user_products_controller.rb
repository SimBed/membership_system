class RelUserProductsController < ApplicationController
  before_action :set_rel_user_product, only: %i[ show edit update destroy ]

  # GET /rel_user_products or /rel_user_products.json
  def index
    @rel_user_products = RelUserProduct.all
  end

  # GET /rel_user_products/1 or /rel_user_products/1.json
  def show
  end

  # GET /rel_user_products/new
  def new
    @rel_user_product = RelUserProduct.new
    @users = User.order_by_name.map { |u| [u.name, u.id] }
    @products = Product.all.map { |p| [p.name, p.id] }
  end

  # GET /rel_user_products/1/edit
  def edit
    @users = User.all.map { |u| [u.name, u.id] }
    @products = Product.all.map { |p| [p.name, p.id] }
  end

  # POST /rel_user_products or /rel_user_products.json
  def create
    @rel_user_product = RelUserProduct.new(rel_user_product_params)

    respond_to do |format|
      if @rel_user_product.save
        format.html { redirect_to @rel_user_product, notice: "Purchase was successfully created." }
        format.json { render :show, status: :created, location: @rel_user_product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @rel_user_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /rel_user_products/1 or /rel_user_products/1.json
  def update
    respond_to do |format|
      if @rel_user_product.update(rel_user_product_params)
        format.html { redirect_to @rel_user_product, notice: "Purchase was successfully updated." }
        format.json { render :show, status: :ok, location: @rel_user_product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @rel_user_product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rel_user_products/1 or /rel_user_products/1.json
  def destroy
    @rel_user_product.destroy
    respond_to do |format|
      format.html { redirect_to rel_user_products_url, notice: "Purchase was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rel_user_product
      @rel_user_product = RelUserProduct.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def rel_user_product_params
      params.require(:rel_user_product).permit(:user_id, :product_id, :dop, :payment)
    end
end
