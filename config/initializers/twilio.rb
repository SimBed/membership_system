Rails.configuration.twilio = {
  account_sid: ENV['TWILIO_ACCOUNT_SID'],
  auth_token: ENV['TWILIO_AUTH_TOKEN'],
  number: ENV['TWILIO_NUMBER'],
  me: ENV['ME'],
  boss: ENV['BOSS'],
  whatsapp_number: ENV['TWILIO_WHATSAPP_NUMBER']
}
