class Whatsapp
  def initialize(attributes = {})
    @receiver = attributes[:receiver]
    @message_type = attributes[:message_type]
    @admin_triggered = attributes[:admin_triggered] || true
    @flash_message = attributes[:flash_message] || true
    @variable_contents = attributes[:variable_contents]
    @to_number = [@receiver.is_a?(Client), @receiver.is_a?(Instructor)].any? ? @receiver.whatsapp_messaging_number : Rails.configuration.twilio[:me]
  end

  def manage_messaging
    # the arrays returned are for the flash
    # https://stackoverflow.com/questions/18071374/pass-rails-error-message-from-model-to-controller
    # commented out this line for client_waiting_list test to pass. Needs reformatting.   
    # return [nil] unless Rails.env.production? || @to_number == Rails.configuration.twilio[:me]
    return [nil] if @message_type == 'early_cancels_no_penalty'

    return [:warning, "Client has no contact number. #{@message_type} details not sent"] if @to_number.nil? && @admin_triggered

    # return [nil] unless white_list_whatsapp_receivers

    send_whatsapp
    post_send_whatsapp_flash
  end

  def send_whatsapp
    twilio_initialise
    client = Twilio::REST::Client.new(@account_sid, @auth_token)
    body = send("body_#{@message_type}")
    client.messages.create(
      from: "whatsapp:#{@from_number}",
      to: "whatsapp:#{@to_number}",
      body:
    )
  end

  private

  def twilio_initialise
    @account_sid = Rails.configuration.twilio[:account_sid]
    @auth_token = Rails.configuration.twilio[:auth_token]
    @from_number = Rails.configuration.twilio[:whatsapp_number]
  end

  def post_send_whatsapp_flash
    return [nil] unless @flash_message == true # note false gets passed as the string 'false' so be careful if reformatting

    return [nil] if @variable_contents[:me?] # reformat - pass flash_message: false instead (think this relates to the SOS message if multiple accounts have been created)

    return [:success, I18n.t(:new_purchase_by_client)] if @message_type == 'new_purchase' && !@admin_triggered

    return [:success, I18n.t(:signup, name: @receiver.first_name)] if @message_type == 'signup'

    # gsub so the flash says 'password reset message sent' not 'password_reset message sent'
    [:warning, I18n.t(:message_sent, message_type: @message_type.gsub('_', ' '), to_number: @to_number)]
    # [:warning, "#{@message_type} message sent to #{@to_number}"]
  end

  # def white_list_whatsapp_receivers
  #   whatsapp_receivers = Setting.whitelist
  #   whatsapp_receivers.include?(@receiver.email.slice(0,7))
  # end

  def body_waiting_list_blast
    "SPOT AVAILABLE AT #{@variable_contents[:wkclass_name].upcase} at #{@variable_contents[:date_time].upcase}" +
    "\nYou have received this message because you are on the waiting list for this class." +  
    "\nBook now, but be quick! Spots are available on a 1st come basis." +
    "\n \nPlease do not reply to this message. Contact The Space's main number if you have any questions."
  end
    
  # space between '\n' and '\nPlease' is required for conformity to nuance of template. Fails to deliver without.
  def body_new_purchase
    "Thank you for your new purchase #{@variable_contents[:first_name]}." +
      "\nPlease log in to your account to stay up to date with your attendance and expiry details." +
      "\n \nPlease do not reply to this message. Contact The Space directly if you have any questions." +
      "\nTerms & Conditions: https://www.thespacefitness.in/terms&conditions"
  end

  def body_package_expiry
    "Hi #{@variable_contents[:first_name]}" +
      "\nYour Group Class Package at The Space expires on #{@variable_contents[:day]}." +
      "\nRenew today & save #{@variable_contents[:discount]}% on your next Group Class Package!. After expiry, full price rates will apply." +
      "\n \nLogin to your account to renew or contact us to discuss more options." +
      "\n \nPlease do not reply to this message. Contact The Space's front desk number if you have any questions."
  end

  def body_trial_expiry
    "Hi #{@variable_contents[:first_name]}" +
      "\nYour Trial at The Space expires on #{@variable_contents[:day]}." +
      "\nRenew before expiry & save #{@variable_contents[:discount]}% on your first Package!" +
      "\n \nLogin to your account to renew or contact us to discuss more options." +
      "\n \nPlease do not reply to this message. Contact The Space directly for renewal."
  end

  def body_new_signup
    "Welcome to The Space #{@receiver.first_name}!" +
      "\n\nYou should already be logged in to your new account." +
      "\nYou will need these details to login in future:" +
      "\nEmail: the email you registered with us" +
      "\nPassword: #{@variable_contents[:password]}" +
      "\n\nYou can change your password to something more memorable on your Profile page." +
      "\n\nPlease do not reply to this message. Contact The Space's main number if you have any questions."
  end

  def body_new_account
    "Welcome to The Space #{@receiver.first_name}!" +
      "\n\nTo see details of your membership, please login:" +
      "\nEmail: the email you registered with us" +
      "\nPassword: #{@variable_contents[:password]}" +
      "\n\nYou can change your password to something more memorable on your Profile page." +
      "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  end

  def body_new_instructor_account
    "Welcome to The Space #{@receiver.first_name}!" +
      "\n\nTo see details of your class payments, please login:" +
      "\nEmail: #{@variable_contents[:email]}" +
      "\nPassword: #{@variable_contents[:password]}" +
      "\n\nPlease do not reply to this message. Contact Gigi directly if you have any questions."
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

  def body_daily_account_limit
    'ACCOUNT DAILY LIMIT WARNING' +
      "\nDan, multiple accounts have been set up today. Please investigate."
  end

  # def body_membership_system_upgrade
  #   'THE SPACE' +
  #     "\nMembership System Upgrade" +
  #     "\n\nDear #{@variable_contents[:first_name]}" +
  #     "\n\nYou may receive a message from us in the coming weeks from this number +18168375076." +
  #     "\nThis is our automated number for communicating information about your Package at The Space. Please save this number in your contacts" +
  #     ' so you do not miss out on important information.' +
  #       "\n\nThank You" +
  #       "\nThe Space" +
  #       "\n\nPlease do not reply to this message. Contact The Space directly if you have any questions."
  # end

  # def body_memorable_password_march27
  #   'MEMBERSHIP SYSTEM UPDATE' +
  #     "\nStruggling to remember your password? You can now set it to something more memorable." +
  #     "\nHead over to your Profile page to change it." +
  #     "\n\nThis is an automated message. Please do not reply here. Contact The Space's main number if you have any questions."
  # end

  # def body_blast
  #   'CLASS UPDATE' +
  #   "\n1) The Space will be closed on 1st May 2023 for Labour Day. Sessions will resume on schedule from 2nd May." +
  #   "\n2) No Pilates on 9th May as Karina is travelling." +
  #   "\n \nPlease plan your workouts accordingly.\n"
  # end
end
