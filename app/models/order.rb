class Order < ApplicationRecord
  include OrderConcerns::Razorpay
  belongs_to :product
  belongs_to :account

  [:authorized, :captured, :refunded, :error].each do |scoped_key|
    scope scoped_key, -> { where('LOWER(status) = ?', scoped_key.to_s.downcase) }
  end

  class << self
    def process_razorpayment(params)
      price = Price.find(params[:price_id]).discounted_price
      Razorpay.setup(Rails.configuration.razorpay[:key_id], Rails.configuration.razorpay[:key_secret])
      razorpay_pmnt_obj = fetch_payment(params[:payment_id])
      status = fetch_payment(params[:payment_id]).status
      if status == "authorized"
        razorpay_pmnt_obj.capture({ amount: price })
        razorpay_pmnt_obj = fetch_payment(params[:payment_id])
        params.merge!({ status: razorpay_pmnt_obj.status,
                        price: price })
        # don't want price_id from params
        Order.create(params.permit(:product_id, :price, :status, :payment_id, :account_id))
      else
        raise StandardError, "Unable to capture payment"
      end
    end

    def process_refund(payment_id)
      fetch_payment(payment_id).refund
      record = Order.find_by_payment_id(payment_id)
      record.update_attributes(status: fetch_payment(payment_id).status)
      return record
    end

    def filter(params)
      scope = params[:status] ? Order.send(params[:status]) : Order.authorized
      return scope
    end
  end
end
