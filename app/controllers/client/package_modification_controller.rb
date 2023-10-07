class Client::PackageModificationController < ApplicationController
  skip_before_action :verify_authenticity_token
  layout 'client'
  before_action :correct_account

  def new_freeze; end

  def buy_freeze
    begin
      # order = Order.create(Order.process_razorpayment(order_params.except(:purchase_id)))
      # if order.status == 'captured'

      if Order.process_razorpayment(order_params)[:status] == 'captured'
        account = Account.find(order_params[:account_id])
        # rearchitect orders and non-package products/purchases
        Order.create(price: 650, status: 'captured', payment_id: order_params[:payment_id], account_id: account.id, client_ui: 'booking page freeze' )
        freeze_params = { purchase_id: order_params[:purchase_id], start_date: order_params[:start_date], end_date: Date.parse(order_params[:start_date]).advance(days:13) }
        @freeze = Freeze.new(freeze_params)
        if @freeze.save
          # flash_message :success, t('.success', name: @client.name)
          flash_message :success, t('.success')
          cancel_bookings_during_freeze(@freeze)
          update_purchase_status([@freeze.purchase])
          # should be logged in as client, but phones have a weird way of deleting sessions so the payment may have been made but the client may no longer be logged in
          if logged_in_as?('client')
            redirect_to client_book_path account.client
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
  end

  def adjust_restart; end
  
  def transfer; end

  def cancel_freeze
    @purchase = Purchase.find(params[:purchase_id])
    render partial: 'client/clients/package_modifications/freeze'
  end

  def cancel_adjust_restart
    render partial: 'client/clients/package_modifications/adjust_restart'
  end

  def cancel_transfer
    render partial: 'client/clients/package_modifications/transfer'
  end

  private

  def correct_account
    @client = Client.find(params[:id])
    redirect_to login_path unless current_account?(@client.account)
  end

  def order_params
    p = params.permit(:purchase_id, :start_date, :razorpay_payment_id, :payment_id, :account_id, :client_ui, :price )
    p.merge!({ payment_id: p.delete(:razorpay_payment_id) || p[:payment_id] })
    p
  end  
end
