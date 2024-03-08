class Blast
  def initialize(attributes = {})
    @receiver = attributes[:receiver]
    @message = attributes[:message]
    @variable_contents = attributes[:variable_contents]
    @to_number = to_number
  end

  def send_whatsapp
    twilio_initialise
    client = Twilio::REST::Client.new(@account_sid, @auth_token)
    body = @message
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

  def to_number
    return @receiver.whatsapp_messaging_number if [@receiver.is_a?(Client), @receiver.is_a?(Instructor)].any?

    return Rails.configuration.twilio[:me] if @receiver == 'me'

    nil
  end
    
  def body_new_purchase
    "Thank you for your new purchase #{@variable_contents[:first_name]}." +
    "\nPlease log in to your account to stay up to date with your attendance and expiry details." +
    "\n\nTEMPORARY ENTRANCE: Please note, due to renovations, our entrance has temporarily relocated. Please use the side entry (enter Silver Beach Estate by silver gates to side of Bayroute, then 2nd set of gold gates)." +
    "\n \nPlease do not reply to this message. Contact The Space directly if you have any questions." +
    "\nTerms & Conditions: https://www.thespacefitness.in/terms&conditions"
  end

end
