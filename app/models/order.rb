class Order < ApplicationRecord
  include OrderConcerns::Razorpay
  belongs_to :product
  belongs_to :account, optional: true

  [:authorized, :captured, :refunded, :error].each do |scoped_key|
    scope scoped_key, -> { where('LOWER(status) = ?', scoped_key.to_s.downcase) }
  end

  class << self
    def process_razorpayment(params)
      # razor deals in paise
      price = Price.find(params[:price_id])
      price_rupees = price.discounted_price
      price_paise = price_rupees * 100
      Razorpay.setup(Rails.configuration.razorpay[:key_id], Rails.configuration.razorpay[:key_secret])
      razorpay_pmnt_obj = fetch_payment(params[:payment_id])
      status = fetch_payment(params[:payment_id]).status
      if status == "authorized"
        razorpay_pmnt_obj.capture({ amount: price_paise })
        razorpay_pmnt_obj = fetch_payment(params[:payment_id])
        params.merge!({ status: razorpay_pmnt_obj.status,
                        price: price_rupees })
        # don't want price_id from params
        # Only use paise for Razor. Use rupees in the Order and Purchase tables.
        Order.create(params.permit(:product_id, :price, :status, :payment_id, :account_id))
      else
        raise StandardError, "Unable to capture payment"
      end
    end

    def process_refund(payment_id)
      fetch_payment(payment_id).refund
      record = Order.find_by_payment_id(payment_id)
      # record.update_attributes(status: fetch_payment(payment_id).status)
      # update_attributes (from RazorPay default code) deprecated
      record.update(status: fetch_payment(payment_id).status)
      return record
    end

    def filter(params)
      scope = params[:status] ? Order.send(params[:status]) : Order.authorized
      return scope
    end
  end
end
