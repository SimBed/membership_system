require "razorpay"

class Razorpay
  def initialize(attributes = {})
    @amount = attributes[:amount]
  end

  def send_whatsapp
    razor_initialise
    Razorpay.setup( @key_id, @key_secret)
    payment = Razorpay::Order.create amount: @amount, currency: 'INR', receipt: 'TEST'
  end

  private

  def razor_initialise
    @key_id = Rails.configuration.razor[:key_id]
    @key_secret = Rails.configuration.razor[:key_secret]
  end

end
