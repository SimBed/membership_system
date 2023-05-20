class Order < ApplicationRecord
  include OrderConcerns::Razorpay
  belongs_to :product
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
      if razorpay_pmnt_obj.status == "authorized"
        razorpay_pmnt_obj.capture({amount: price_paise})
        params.merge!({status: fetch_payment(params[:payment_id]).status}).except(:price_id)                
      else
        raise StandardError, "Unable to capture payment"
      end
    end

    def process_refund(payment_id)
      fetch_payment(payment_id).refund
      record = Order.find_by_payment_id(payment_id)
      record.update(status: fetch_payment(payment_id).status)
      return record
    end

    def filter(params)
      scope = params[:status] ? Order.send(params[:status]) : Order.captured
      return scope
    end
  end
end
