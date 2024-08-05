class Order #< ApplicationRecord
  include OrderConcerns::Razorpay

  class << self
    def proceed_to_completion(payment_id)
      orig_payment = Razorpay::Payment.fetch(payment_id)
      orig_payment.capture(amount: payment.amount) if orig_payment.status == 'authorised'
      payment = Razorpay::Payment.fetch(payment_id)
      return true if payment.status == 'captured' || payment.method =='upi' # upi payments fail to capture (but money still taken from client) causing completion not to occur and subequent admin intervention
    end

  end
end
