class Superadmin::OrdersController < Superadmin::BaseController
  skip_before_action :verify_authenticity_token
  skip_before_action :superadmin_account, only: [:create]
  before_action :client_account, only: [:create]
  before_action :set_order, only: [:show, :refund]

  def index
    @orders = Order.filter(filter_params).includes(:account).order_by_date.page(params[:page]).per(20)
  end

  def show
  end

  def create
    begin
      # don't want price_id from params
      # Order's #process_razorpayment captures the payment and returns a slightly altered hash to the one we send it (without the price_id we no longer need,
      # with a an actual price amount (in rupees) and the Razorpay object's status ('captured')
      order = Order.create(Order.process_razorpayment(order_params))
      if order.status == 'captured'
        account = Account.find(order_params[:account_id])
        purchase_params = { client_id: account.client.id, product_id: order.product_id, price_id: order_params[:price_id],
                            payment: order.price, dop: Time.zone.today, payment_mode: 'Razorpay', status: 'not started' }
        @purchase = Purchase.new(purchase_params)
        if @purchase.save
          flash_message(*Whatsapp.new(whatsapp_params('renew')).manage_messaging)
          redirect_to client_history_path account.client if logged_in? 
        else
          flash[:alert] = "Unable to process payment."
          redirect_to root_path
        end
      end

    rescue Exception
      flash[:alert] = "Unable to process payment."
      redirect_to root_path
    end
  end

  def whatsapp_params(message_type)
    { receiver: @purchase.client,
      message_type: message_type,
      admin_triggered: false,      
      variable_contents: { name:  @purchase.client.first_name } }
  end

  def refund
    begin
      payment_id = Order.find_by_id(params[:id]).payment_id
      @order = Order.process_refund(payment_id)
      redirect_to :action => "show", :id => @order.id
    rescue Exception
      flash[:alert] = "Unable to refund payment (probably not enough credit on account)."
      redirect_to superadmin_orders_path
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    p = params.permit(:product_id, :account_id, :price_id, :razorpay_payment_id, :payment_id, :client_ui)
    p.merge!({payment_id: p.delete(:razorpay_payment_id) || p[:payment_id]})
    p
  end

  def filter_params
    params.permit(:status, :page)
  end

end
