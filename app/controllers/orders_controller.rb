class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_order, only: [:show, :refund]

  def index
    @orders = Order.filter(filter_params).includes(:account).page(params[:page]).per(20)
  end

  def show
  end

  def create
    begin
      byebug
      @order = Order.process_razorpayment(order_params)
      # redirect_to :action => "show", :id => @order.id
      # if @order.cpatured maybe create account, create purchase and send twillio
      redirect_to orders_path
    rescue Exception
      flash[:alert] = "Unable to process payment."
      redirect_to root_path
    end
  end

  def refund
    payment_id = Order.find_by_id(params[:id]).payment_id
    @order = Order.process_refund(payment_id)
    redirect_to :action => "show", :id => @order.id
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    p = params.permit(:product_id, :account_id, :razorpay_payment_id, :payment_id, :price)
    p.merge!({payment_id: p.delete(:razorpay_payment_id) || p[:payment_id]})
    p
  end

  def filter_params
    params.permit(:status, :page)
  end

end
