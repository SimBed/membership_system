class PurchasesController < ApplicationController
  before_action :set_purchase, only: %i[ show edit update destroy ]

  # GET /purchases or /purchases.json
  def index
    @purchases = Purchase.all
    # it is not critical that expired purchases are identifiable at database level. This will just improve efficiency as the number of purchases gets biggger over time.
    # For example, the form for adding a new attendance makes qualifying purchases available from a select box. It is inefficient
    # to have to run ruby code on the entire population of purchases to identify the non-expired purchases.
    # There are probably more appropriate ways of updating the purchase's status at database level, but running some code
    # here is inoccuous (negligibly slows down a non-speed-critical page) and means the database will be kept up to data intermittently which achieves the aim.
    expire_purchases
  end

  # GET /purchases/1 or /purchases/1.json
  def show
  end

  # GET /purchases/new
  def new
    @purchase = Purchase.new
    @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    @products = Product.all.map { |p| [p.name, p.id] }
  end

  # GET /purchases/1/edit
  def edit
    @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    @products = Product.all.map { |p| [p.name, p.id] }
  end

  # POST /purchases or /purchases.json
  def create
    @purchase = Purchase.new(purchase_params)

    respond_to do |format|
      if @purchase.save
        format.html { redirect_to @purchase, notice: "Purchase was successfully created." }
        format.json { render :show, status: :created, location: @purchase }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /purchases/1 or /purchases/1.json
  def update
    respond_to do |format|
      if @purchase.update(purchase_params)
        format.html { redirect_to @purchase, notice: "Purchase was successfully updated." }
        format.json { render :show, status: :ok, location: @purchase }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @purchase.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /purchases/1 or /purchases/1.json
  def destroy
    @purchase.destroy
    respond_to do |format|
      format.html { redirect_to purchases_url, notice: "Purchase was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

    def expire_purchases
      Purchase.not_expired.each do |p|
        p.update({expired: true}) if p.expired?
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_purchase
      @purchase = Purchase.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def purchase_params
      params.require(:purchase).permit(:client_id, :product_id, :payment, :dop, :payment_mode, :invoice, :note, :adjust_restart, :ar_payment, :ar_date)
    end
end
