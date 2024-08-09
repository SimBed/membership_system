class Order #< ApplicationRecord
  include OrderConcerns::Razorpay

  class << self
    def proceed_to_completion(payment_id)
      payment = Razorpay::Payment.fetch(payment_id)
      if payment.status == 'authorised'
        payment.capture(amount: orig_payment.amount) 
        payment = Razorpay::Payment.fetch(payment_id)
      end
      return true if payment.status == 'captured' || payment.method =='upi' # upi payments fail to capture (but money still taken from client) causing completion not to occur and subequent admin intervention
    end

  end
end