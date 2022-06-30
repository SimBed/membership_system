class Whatsapp
  def initialize(attributes = {})
    @to = attributes[:to]
    @message_type = attributes[:message_type]
    @variable_contents = attributes[:variable_contents]
  end

  def send_whatsapp
    twilio_initialise
    client = Twilio::REST::Client.new(@account_sid, @auth_token)
    body = send("body_#{@message_type}")
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

  def body_no_show_penalty
    "Sorry you missed your class for #{@variable_contents[:name]} on #{@variable_contents[:day]}." +
      "\nPlease try and make changes to your bookings in time to avoid late cancellation and no-show deductions." +
      "\nA deduction has been applied to your Package this time, in line with the no-show policy." +
      "\nPlease log in to your account to see updated attendance and expiry details." +
      "\n \nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_no_show_no_penalty
    "Sorry you missed your class for #{@variable_contents[:name]} on #{@variable_contents[:day]}." +
      "\nPlease try and make changes to your bookings in time to avoid late cancellation and no-show deductions." +
      "\nA deduction has not been applied to your Package this time. If you no-show again, a deduction will apply, in line with the no-show policy." +
      "\nPlease log in to your account to see attendance and expiry details." +
      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_late_cancel_penalty
    "Thanks for letting us know you couldn't make your class for #{@variable_contents[:name]} on #{@variable_contents[:day]}." +
      "\nPlease try and make changes to your bookings in time to avoid late cancellation and no-show deductions." +
      "\nA deduction has been applied to your Package this time, in line with the late cancellation policy." +
      "\nPlease log in to your account to see updated attendance and expiry details." +
      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_late_cancel_no_penalty
    "Thanks for letting us know you couldn't make your class for #{@variable_contents[:name]} on #{@variable_contents[:day]}." +
      "\nPlease try and make changes to your bookings in time to avoid late cancellation and no-show deductions." +
      "\nA deduction has not been applied to your Package this time. If you cancel late again, a deduction may apply, in line with the late cancellation policy." +
      "\nPlease log in to your account to see attendance and expiry details." +
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

  def test
    "Thanks for all the templates. We would be delighted to resubmit all the templates."
  end
end
