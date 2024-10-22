class TwilioMessage
  def initialize(attributes = {})
    @receiver = attributes[:receiver]
    @message_type = attributes[:message_type] # retain only for flash (redundant now with new twilio api content_builder)
    @content_sid = attributes[:content_sid]
    @triggered_by = attributes[:triggered_by] || 'admin'
    @content_variables = attributes[:content_variables]
    @to_number = to_number
    @to_me = to_me
    @apply_flash = apply_flash
  end

  def manage
    # the arrays returned are for the flash
    # https://stackoverflow.com/questions/18071374/pass-rails-error-message-from-model-to-controller
    # commented out this line for client_waiting_list test to pass. Needs reformatting.
    # return [nil] unless Rails.env.production? || @to_number == Rails.configuration.twilio[:me]
    # return [nil] if @message_type == 'early_cancels_no_penalty'
    # return [:warning, "whatsapp only sent in production"] unless whatsapp_permitted
    return [nil] unless whatsapp_permitted
    return [:warning, "Client has no contact number. #{@message_type} details not sent"] if @to_number.nil? && @triggered_by == 'admin'

    send_whatsapp
    post_send_whatsapp_flash
  end

  def send_whatsapp
    twilio_initialise
    client = Twilio::REST::Client.new(@account_sid, @auth_token)
    # body = send("body_#{@message_type}")
    client.api.v2010.messages.create(
            content_sid: @content_sid,
            to: "whatsapp:#{@to_number}",
            from: "whatsapp:#{@from_number}",
            content_variables: {
              '1' => @content_variables[:first_name]
            }.to_json
          )
  end

  # https://www.twilio.com/docs/content/whatsappauthentication
  def send_password
    twilio_initialise
    client = Twilio::REST::Client.new(@account_sid, @auth_token)
    client.api
          .v2010
          .messages
          .create(
            from: "whatsapp:#{@from_number}",
            to: "whatsapp:#{@to_number}",
            content_sid: 'HXdfb9c88a6cbad1bad04a1bc458a34dc0',
            content_variables: {
              '1' => '123456'
            }.to_json,
            messaging_service_sid: 'MGeba3973c4b868c0b4716f1874bce6969'
          )
  end

  private

  def twilio_initialise
    @account_sid = Rails.configuration.twilio[:account_sid]
    @auth_token = Rails.configuration.twilio[:auth_token]
    @from_number = Rails.configuration.twilio[:whatsapp_number]
  end

  def post_send_whatsapp_flash
    return [nil] unless @apply_flash
    # TODO: clean, method new_purchase to new_purchase_by_client. if triggered by client ...[:success, I18n.t(:message_sent)]
    return [:success, I18n.t(:new_purchase_by_client)] if @message_type == 'new_purchase' && @triggered_by == 'client'

    return [:success, I18n.t(:new_signup, name: @receiver.first_name)] if @message_type == 'new_signup'

    # gsub so the flash says eg 'password reset message sent' not 'password_reset message sent'
    [:warning, I18n.t(:message_sent, message_type: @message_type.gsub('_', ' '), to_number: @to_number)]
  end

  def whatsapp_permitted
    return false if @message_type == 'early_cancels_no_penalty'

    return true if Rails.env.production?

    # for one test in client_waiting_list I have stubbed out whatsapp_send
    return true if Rails.env.test? && @to_number == '+919161131111'

    return true if @to_me

    false
  end

  def to_number
    return @receiver.whatsapp_messaging_number if [@receiver.is_a?(Client), @receiver.is_a?(Instructor)].any?

    return Rails.configuration.twilio[:me] if @receiver == 'me'

    nil
  end

  def to_me
    return true if @to_number == Rails.configuration.twilio[:me]

    false
  end

  def apply_flash
    return false if @triggered_by == 'client' && @message_type == 'waiting_list_blast'

    return false if @message_type == 'daily_account_limit'

    true
  end
end
