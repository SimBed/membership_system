class Whatsapp
  def initialize(attributes = {})
    @receiver = attributes[:receiver]
    @message_type = attributes[:message_type]
    @variable_contents = attributes[:variable_contents]
    @to_number = @receiver.whatsapp_messaging_number
  end

  def manage_messaging
    # https://stackoverflow.com/questions/18071374/pass-rails-error-message-from-model-to-controller
    return [nil] if @message_type == 'early_cancels_no_penalty'

    return [:warning, "Client has no contact number. #{@message_type} details not sent"] if @to_number.nil?

    # return [nil] unless white_list_whatsapp_receivers
    # return [:warning, "Personal Training purchase. Send details to client manually."] if @receiver.pt? && @message_type == 'new_purchase'

    # return [nil] unless Rails.env.production?

    send_whatsapp
    [:warning, "#{@message_type} message sent to #{@to_number}"]
  end

  def send_whatsapp
    twilio_initialise
    client = Twilio::REST::Client.new(@account_sid, @auth_token)
    body = send("body_#{@message_type}")
    client.messages.create(
      from: "whatsapp:#{@from_number}",
      to: "whatsapp:#{@to_number}",
      body: body
    )
  end

  private

  def twilio_initialise
    @account_sid = Rails.configuration.twilio[:account_sid]
    @auth_token = Rails.configuration.twilio[:auth_token]
    @from_number = Rails.configuration.twilio[:whatsapp_number]
  end

  # def white_list_whatsapp_receivers
  #   whatsapp_receivers = %w[Amala Aadrak Fluke Cleo James]
  #   whatsapp_receivers.include?(@receiver.first_name)
  # end
  def white_list_whatsapp_receivers
    # whatsapp_receivers = %w[nishaap trivedi james@t]
    whatsapp_receivers = Setting.whitelist
    whatsapp_receivers.include?(@receiver.email.slice(0,7))
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

  def body_no_shows_penalty
    "Sorry you missed your class for #{@variable_contents[:name]} on #{@variable_contents[:day]}." +
      "\nPlease try and make changes to your bookings in time to avoid late cancellation and no-show deductions." +
      "\nA deduction has been applied to your Package this time, in line with the no-show policy." +
      "\nPlease log in to your account to see updated attendance and expiry details." +
      "\n \nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_no_shows_no_penalty
    "Sorry you missed your class for #{@variable_contents[:name]} on #{@variable_contents[:day]}." +
      "\nPlease try and make changes to your bookings in time to avoid late cancellation and no-show deductions." +
      "\nA deduction has not been applied to your Package this time. If you no-show again, a deduction will apply, in line with the no-show policy." +
      "\nPlease log in to your account to see attendance and expiry details." +
      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_late_cancels_penalty
    "Thanks for letting us know you couldn't make your class for #{@variable_contents[:name]} on #{@variable_contents[:day]}." +
      "\nPlease try and make changes to your bookings in time to avoid late cancellation and no-show deductions." +
      "\nA deduction has been applied to your Package this time, in line with the late cancellation policy." +
      "\nPlease log in to your account to see updated attendance and expiry details." +
      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_late_cancels_no_penalty
    "Thanks for letting us know you couldn't make your class for #{@variable_contents[:name]} on #{@variable_contents[:day]}." +
      "\nPlease try and make changes to your bookings in time to avoid late cancellation and no-show deductions." +
      "\nA deduction has not been applied to your Package this time. If you cancel late again, a deduction may apply, in line with the late cancellation policy." +
      "\nPlease log in to your account to see attendance and expiry details." +
      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_password_reset
    'Thank you for your request to reset your password. If you are not expecting this message, please notify The Space.' +
      "\n\nTo see details of your membership, please login with your new password:" +
      "\nEmail: the email you registered with us" +
      "\nPassword: #{@variable_contents[:password]}" +
      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_new_booking
    'Thank you for booking for HIIT on Monday.' +
      "\nYou can cancel this booking up to 3 hours before the class start time without incurring any penalty." +
      "\n \nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_membership_system_upgrade
    'THE SPACE' +
      "\nMembership System Upgrade" +
      "\n\nDear #{@variable_contents[:first_name]}" +
      "\n\nYou may receive a message from us in the coming weeks from this number +18168375076." +
      "\nThis is our automated number for communicating information about your Package at The Space. Please save this number in your contacts" +
      " so you do not miss out on important information." +
      "\n\nThank You" +
      "\nThe Space" +

      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_temp_email_confirm
    "The email for the last message is: #{@variable_contents[:email]}"
  end

  def body_test
    "Thanks for all the templates. We would be delighted to resubmit all the templates.\nReply directly\nhttps://api.whatsapp.com/send/?phone=919619348427&text&type=phone_number&app_absent=0"
  end
end
