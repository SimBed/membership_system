class Order < ApplicationRecord
  include OrderConcerns::Razorpay
  belongs_to :product, optional: true
  belongs_to :account, optional: true
  scope :order_by_date, -> { order(created_at: :desc) }

  [:authorized, :captured, :refunded, :error].each do |scoped_key|
    scope scoped_key, -> { where('LOWER(status) = ?', scoped_key.to_s.downcase) }
  end

  class << self
    def process_razorpayment(params)
      # Razorpay deals in paise. Everywhere else (Order and Purchase tables) we use rupees.
      price_rupees = params[:price].to_i
      price_paise = price_rupees * 100
      Razorpay.setup(Rails.configuration.razorpay[:key_id], Rails.configuration.razorpay[:key_secret])
      razorpay_pmnt_obj = fetch_payment(params[:payment_id])
      raise StandardError, 'Unable to capture payment' unless razorpay_pmnt_obj.status == 'authorized'

      razorpay_pmnt_obj.capture({ amount: price_paise })
      params.merge!({ status: fetch_payment(params[:payment_id]).status }).except(:price_id)
    end

    # This is not really the right place for this class method (in Order) but it is convenient (for now) so it can be stubbed in testing
    def payment_status_check(payment_id)
      payment = Razorpay::Payment.fetch(payment_id)
      payment.capture(amount: payment.amount) if payment.status == 'authorised'
      Razorpay::Payment.fetch(payment_id).status
    end     

    # def process_refund(payment_id)
    #   fetch_payment(payment_id).refund
    #   record = Order.find_by_payment_id(payment_id)
    #   record.update(status: fetch_payment(payment_id).status)
    #   return record
    # end

    def filter(params)
      params[:status] ? Order.send(params[:status]) : Order.captured
    end
  end
end
