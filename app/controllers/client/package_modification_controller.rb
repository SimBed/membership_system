class Client::PackageModificationController < Client::BaseController
  skip_before_action :verify_authenticity_token

  def new_freeze
    @purchase = Purchase.find(params[:purchase_id])
    @default_start_dates = @purchase.new_freeze_dates
    render 'freeze_form'
  end

  def restart
    render 'restart_form'
  end

  def transfer
    render 'transfer_form'
  end

  def cancel_freeze
    @purchase = Purchase.find(params[:purchase_id])
    render partial: 'client/package_modification/freeze_button'
  end

  def cancel_restart
    render partial: 'client/package_modification/restart_button'
  end

  def cancel_transfer
    render partial: 'client/package_modification/transfer_button'
  end

  # private

  # def freeze_params
  #   { purchase_id: order_params[:purchase_id],
  #     start_date: order_params[:start_date],
  #     end_date: Date.parse(order_params[:start_date]).advance(days: Setting.freeze_duration_days - 1),
  #     note: nil,
  #     medical: false,
  #     doctor_note: false,
  #     added_by: 'client',
  #     payment_attributes: {dop: Time.zone.today, amount: order_params[:price].to_i, payment_mode: 'Razorpay', online: true, note: nil}
  #    }
  # end

  # def order_params
  #   # see orders controller order_params method for some explanation
  #   p = params.permit(:purchase_id, :account_id, :start_date, :client_ui, :price, :razorpay_payment_id, :payment_id)
  #   p.merge!({ payment_id: p.delete(:razorpay_payment_id) || p[:payment_id] })
  #   p
  #  # delete(key) → value. Deletes the key-value pair and returns the value from hsh whose key is equal to key
  #  # so the :razorpay_payment_id is switched to :payment_id key
  #  # #<ActionController::Parameters {"purchase_id"=>"821", "start_date"=>"2024-02-15", "account_id"=>"3", "client_ui"=>"shop page", "price"=>"650", "payment_id"=>"pay_Nah0Nx1uFw5rta"} permitted: true>
  # end
end
