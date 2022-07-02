module WhatsappNumber
  extend ActiveSupport::Concern

  included do
    def number_formatted(contact_type)
      number = send(contact_type)&.gsub(/[^0-9+]/, '')
      return "+91#{number}" unless (number&.first == '+' || number.blank?)

      number
    end

    def whatsapp_messaging_number
      # #find returns first element meeting block condition
      [number_formatted('whatsapp'), number_formatted('phone')].find(&:present?)
    end
  end
end
