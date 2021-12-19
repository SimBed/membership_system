class PurchasesController < ApplicationController
  before_action :set_purchase, only: %i[ show edit update destroy ]

  def index
    # convoluted but seems ok way to sort by date descending when date is part of a multiple parameter sort
    @purchases = Purchase.all.sort_by { |p| [p.client.name, -p.dop&.to_time.to_i] }
    # it is not critical that expired purchases are identifiable at database level. This will just improve efficiency as the number of purchases gets biggger over time.
    # For example, the form for adding a new attendance makes qualifying purchases available from a select box. It is inefficient
    # to have to run ruby code on the entire population of purchases to identify the non-expired purchases.
    # There are probably more appropriate ways of updating the purchase's status at database level, but running some code
    # here is inoccuous (negligibly slows down a non-speed-critical page) and means the database will be kept up to data intermittently which achieves the aim.
    expire_purchases
  end

  def show
  end

  def new
    @purchase = Purchase.new
    @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    @products = Product.all.map { |p| [p.name, p.id] }
    @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
  end

  def edit
    @clients = Client.order_by_name.map { |c| [c.name, c.id] }
    @products = Product.all.map { |p| [p.name, p.id] }
    @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
  end

  def create
    @purchase = Purchase.new(purchase_params)
      if @purchase.save
        redirect_to @purchase
        flash[:success] = "Purchase was successfully created"
      else
        @clients = Client.order_by_name.map { |c| [c.name, c.id] }
        @products = Product.all.map { |p| [p.name, p.id] }
        @payment_methods = Rails.application.config_for(:constants)["payment_methods"]
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @purchase.update(purchase_params)
        redirect_to @purchase
        flash[:success] = "Purchase was successfully updated"
      else
        render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase.destroy
      redirect_to purchases_url
      flash[:success] = "Purchase was successfully deleted"
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
      params.require(:purchase).permit(:client_id, :product_id, :payment, :dop, :payment_mode, :invoice, :note, :adjust_restart, :ar_payment, :ar_date)
    end
end
