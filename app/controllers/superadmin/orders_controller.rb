class Superadmin::OrdersController < Superadmin::BaseController
  skip_before_action :verify_authenticity_token
  skip_before_action :superadmin_account, only: [:create]
  # this before filter created issues on phones where overzealous browsers deleted sessions (so logging the client out) while the razorpay button was still active and used
  # before_action :client_account, only: [:create]
  before_action :set_order, only: [:show, :refund]

  def index
    @pagy, @orders = pagy(Order.filter(filter_params).includes(:account).order_by_date)
  end

  def show; end

  def create
    # don't want price_id from params
    # Order's #process_razorpayment captures the payment and returns a slightly altered hash to the one we send it (without the price_id we no longer need,
    # with an actual price amount (in rupees) and the Razorpay object's status ('captured')
    order = Order.create(Order.process_razorpayment(order_params))
    if order.status == 'captured'
      account = Account.find(order_params[:account_id])
      purchase_params = { client_id: account.client.id, product_id: order.product_id, price_id: order_params[:price_id],
                          charge: order.price, dop: Time.zone.today, payment_mode: 'Razorpay', status: 'not started', payment_attributes: {dop: Time.zone.today, amount: order.price, payment_mode: 'Razorpay', online: true, note: nil} }
      @purchase = Purchase.new(purchase_params)
      if @purchase.save
        [:renewal_discount_id, :status_discount_id, :oneoff_discount_id].each do |discount|
          DiscountAssignment.create(purchase_id: @purchase.id, discount_id: params[discount].to_i) if params[discount].present?
        end
        flash_message(*Whatsapp.new(whatsapp_params('new_purchase')).manage_messaging)
        # should be logged in as client, but phones have a weird way of deleting sessions so the payment may have been made but the client may no longer be logged in
        if logged_in_as?('client')
          client = account.client
          # client.declaration ? redirect_to(client_history_path(client)) : redirect_to(new_client_declaration_path(client))
          redirect_to client_history_path(client)
        else
          flash[:warning] = 'Your browser may have logged you out of the system. Please login again to see your purchase and book your classes'
          redirect_to login_path
        end
      else
        flash[:alert] = 'Unable to process payment.'
        redirect_to root_path
      end
    end
  rescue Exception
    flash[:danger] = 'Unable to process payment. Please contact The Space'
    redirect_to root_path
  end

  def whatsapp_params(message_type)
    { receiver: @purchase.client,
      message_type:,
      triggered_by: 'client',
      variable_contents: { first_name: @purchase.client.first_name } }
  end

  # def refund
  #   begin
  #     payment_id = Order.find_by_id(params[:id]).payment_id
  #     @order = Order.process_refund(payment_id)
  #     redirect_to action: 'show', id: @order.id
  #   rescue Exception
  #     flash[:alert] = 'Unable to refund payment (probably not enough credit on account).'
  #     redirect_to superadmin_orders_path
  #   end
  # end

  private

  def set_order
    @order = Order.find(params[:id])
  end

  def order_params
    p = params.permit(:product_id, :account_id, :price_id, :price, :razorpay_payment_id, :payment_id, :client_ui)
    # delete returns nil if the key doesn't exist and the key's value if it does.
    p.merge!({ payment_id: p.delete(:razorpay_payment_id) || p[:payment_id] })
    p
  end

  def filter_params
    params.permit(:status, :page)
  end
end
