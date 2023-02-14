class Superadmin::OrdersController < Superadmin::BaseController
  skip_before_action :verify_authenticity_token
  skip_before_action :superadmin_account, only: [:create]
  before_action :set_order, only: [:show, :refund]

  def index
    @orders = Order.filter(filter_params).includes(:account).page(params[:page]).per(20)
  end

  def show
  end

  def create
    begin
      @order = Order.process_razorpayment(order_params)
      # redirect_to :action => "show", :id => @order.id
      # if @order.cpatured maybe create account, create purchase and send twillio
      if @order.status == 'captured'
        if logged_in_as?('client')
          #renewed_purchase = Purchase.find(order_params[:purchase_id])
          purchase_params = { client_id: current_account.clients.first.id, product_id: @order.product_id, price_id: order_params[:price_id],
                              payment: @order.price, dop: Time.zone.today, payment_mode: 'Razorpay', status: 'not started' }
          @purchase = Purchase.new(purchase_params)
          if @purchase.save
            flash_message(*Whatsapp.new(whatsapp_params('renew')).manage_messaging)
            redirect_to client_history_path current_account.clients.first
            # redirect_to client_book_path current_account.clients.first
          else
            flash[:alert] = "Unable to process payment."
            redirect_to root_path
          end
        else
          redirect_to thankyou_path
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
    p = params.permit(:product_id, :account_id, :price_id, :razorpay_payment_id, :payment_id)
    p.merge!({payment_id: p.delete(:razorpay_payment_id) || p[:payment_id]})
    p
  end

  def filter_params
    params.permit(:status, :page)
  end

end
