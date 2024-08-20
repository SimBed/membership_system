class Superadmin::OrdersController < Superadmin::BaseController
  skip_before_action :verify_authenticity_token
  skip_before_action :superadmin_account, only: [:create, :verify_payment]
  # this before filter created issues on phones where overzealous browsers deleted sessions (so logging the client out) while the razorpay button was still active
  # before_action :client_account, only: [:create]

  def create
    amount = params[:amount].to_i # Amount in paise (e.g., 50000 for Rs 500)
    Razorpay.setup(Rails.configuration.razorpay[:key_id], Rails.configuration.razorpay[:key_secret])
    # per Razorpay support #12133191 17/8/2024 pass payment_capture: true (to resolve intermittent issue with payments not auto-capturing)
    # payment: {capture: 'automatic'} shown here https://razorpay.com/docs/payments/payments/capture-settings/api/
    # when adding capture, it fails without all the capture_options also
    order = Razorpay::Order.create(amount: amount, currency: 'INR', receipt: SecureRandom.hex(10),
                                   payment: {capture: "automatic",
                                             capture_options: {automatic_expiry_period: 12,
                                                               manual_expiry_period: 7200,
                                                               refund_speed: "normal"}
                                            }
                                   )
    render json: { order_id: order.id, amount: amount }
  rescue Exception
    # javascript makes this request so provide a json response, as expected
    render json: { order_id: nil, error_message: I18n.t('.unable_to_process_payment') }
    # flash_message :danger, I18n.t('.unable_to_process_payment')
    # redirect_to root_path
  end

  def verify_payment
    # https://apidock.com/rails/Object/presence
    payment_id = params[:razorpay_payment_id].presence
    order_id = params[:order_id].presence
    signature = params[:razorpay_signature]
    unable_to_verify_payment && return if [payment_id, order_id].any?(nil) || signature == 'undefined'
    if Razorpay::Utility.verify_payment_signature(razorpay_order_id: order_id, razorpay_payment_id: payment_id, razorpay_signature: signature)
      if Order.proceed_to_completion(payment_id)      
        complete_membership_purchase if params[:purchase_type] == 'membership'
        complete_freeze_purchase if params[:purchase_type] == 'membership_freeze' 
      else
        unable_to_verify_payment
      end
    else
      unable_to_verify_payment
    end
    rescue => e
      flash[:warning] = "Error during payment verification: #{e.message}"
      redirect_to login_path
  end

  private
  def complete_membership_purchase
    account = Account.find(order_params[:account_id])
    price = order_params[:price]
    purchase_params = { client_id: account.client.id, product_id: order_params[:product_id], price_id: order_params[:price_id],
                        charge: price, dop: Time.zone.today, status: 'not started',
                        payment_attributes: {dop: Time.zone.today, amount: price, payment_mode: 'Razorpay', online: true, note: nil} }
    @purchase = Purchase.new(purchase_params)
    if @purchase.save
      [:renewal_discount_id, :status_discount_id, :oneoff_discount_id].each do |discount|
        DiscountAssignment.create(purchase_id: @purchase.id, discount_id: params[discount].to_i) if params[discount].present?
      end
      flash_message(*Whatsapp.new(whatsapp_params('new_purchase')).manage_messaging)
      # should be logged in as client, but phones have a weird way of deleting sessions so the payment may have been made but the client may no longer be logged in
      if logged_in_as?('client')
        client = account.client
        flash_message :success, 'Development Flash - Success' if Rails.env.development?
        # client.declaration ? redirect_to(client_history_path(client)) : redirect_to(new_client_declaration_path(client))
        redirect_to client_history_path(client)
      else
        flash[:warning] = 'Your browser may have logged you out of the system. Please login again to see your purchase and book your classes.'
        redirect_to login_path
      end
    else
      flash[:alert] = 'Please contact The Space. We have been unable to complete yopur purchase.'
      redirect_to root_path
    end

    rescue Exception
      flash[:danger] = 'Your payment may have been made, however we are unable to complete your purchase. Please contact The Space.'
      redirect_to root_path
  end

  def complete_freeze_purchase
      account = Account.find(order_params[:account_id])
      # rearchitect orders and non-package products/purchases
      # Order.create(price: Setting.freeze_charge, status: 'captured', payment_id: order_params[:payment_id], account_id: account.id, client_ui: 'booking page freeze')
      @freeze = Freeze.new(freeze_params)
      if @freeze.save
        # flash_message :success, t('.success', name: @client.name)
        flash_message :success, t('.freeze_success')
        cancel_bookings_during_freeze(@freeze)
        update_purchase_status([@freeze.purchase])
        # should be logged in as client, but phones have a weird way of deleting sessions so the payment may have been made but the client may no longer be logged in
        if logged_in_as?('client')
          redirect_to client_bookings_path account.client
        else
          flash[:warning] = 'Your browser may have logged you out of the system. Please login again to see your purchase and book your classes'
          redirect_to login_path
        end
      else
        flash[:alert] = 'Unable to process payment.'
        redirect_to root_path
      end

    rescue Exception
      flash_message :danger, I18n.t('.unable_to_process_payment')
      redirect_to root_path    
  end  

  def unable_to_verify_payment
    flash_message :danger, I18n.t('.unable_to_verify_payment')
    client = current_account.client
    fallback_route = client ? client_shop_path(client) : root_path
    redirect_back_or_to(fallback_route)
  end

  def whatsapp_params(message_type)
    { receiver: @purchase.client,
      message_type:,
      triggered_by: 'client',
      variable_contents: { first_name: @purchase.client.first_name } }
  end

  def order_params
    p = params.permit(:product_id, :account_id, :price_id, :price, :razorpay_payment_id, :payment_id, :client_ui)
    # delete returns nil if the key doesn't exist and the key's value if it does.
    p.merge!({ payment_id: p.delete(:razorpay_payment_id) || p[:payment_id] })
    p
   # delete(key) → value. Deletes the key-value pair and returns the value from hsh whose key is equal to key
   # so the :razorpay_payment_id is switched to :payment_id key
   # #<ActionController::Parameters {"purchase_id"=>"821", "start_date"=>"2024-02-15", "account_id"=>"3", "client_ui"=>"shop page", "price"=>"650", "payment_id"=>"pay_Nah0Nx1uFw5rta"} permitted: true>    
  end

  def freeze_params
    { purchase_id: freeze_order_params[:purchase_id],
      start_date: freeze_order_params[:start_date],
      end_date: Date.parse(freeze_order_params[:start_date]).advance(days: Setting.freeze_duration_days - 1),
      note: nil,
      medical: false,
      doctor_note: false,
      added_by: 'client',
      payment_attributes: {dop: Time.zone.today, amount: freeze_order_params[:price].to_i, payment_mode: 'Razorpay', online: true, note: nil}
     }
  end

  def freeze_order_params
    # see orders controller order_params method for some explanation
    p = params.permit(:purchase_id, :account_id, :start_date, :client_ui, :price, :razorpay_payment_id, :payment_id)
    p.merge!({ payment_id: p.delete(:razorpay_payment_id) || p[:payment_id] })
    p
   # delete(key) → value. Deletes the key-value pair and returns the value from hsh whose key is equal to key
   # so the :razorpay_payment_id is switched to :payment_id key
   # #<ActionController::Parameters {"purchase_id"=>"821", "start_date"=>"2024-02-15", "account_id"=>"3", "client_ui"=>"shop page", "price"=>"650", "payment_id"=>"pay_Nah0Nx1uFw5rta"} permitted: true>
  end  

end
