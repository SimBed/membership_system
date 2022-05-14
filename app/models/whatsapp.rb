class Whatsapp
  def initialize(attributes = {})
    @to = attributes[:to]
    @message_type = attributes[:message_type]
    @variable_contents = attributes[:variable_contents]
  end

  def send_whatsapp
    twilio_initialise
    client = Twilio::REST::Client.new(@account_sid, @auth_token)
    body = self.send("body_#{@message_type}")
    client.messages.create(
      from: "whatsapp:#{@from}",
      to: "whatsapp:#{@to}",
      body: body
    )
  end

  private

  def twilio_initialise
    @account_sid = Rails.configuration.twilio[:account_sid]
    @auth_token = Rails.configuration.twilio[:auth_token]
    @from = Rails.configuration.twilio[:whatsapp_number]
  end

  # space between '\n' and '\nPlease' is required for conformity to nuance of template. Fails to deliver without.
  def body_new_purchase
    'Thank you for your new purchase.' +
      "\nPlease log in to your account to stay up to date with your attendance and expiry details." +
      "\n \nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_new_account
    'Welcome to The Space!' +
      "\n\nTo see details of your membership, please login:" +
      "\nEmail: the email you registered with us" +
      "\nPassword: #{@variable_contents[:password]}" +
      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_new_booking
    'Thank you for booking for HIIT on Monday.' +
      "\nYou can cancel this booking up to 3 hours before the class start time without incurring any penalty." +
      "\n \nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_temp_email_confirm
    "The email for the last message is: #{@variable_contents[:email]}"
  end
end
