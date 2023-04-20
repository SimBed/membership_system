module WhatsappNumber
  extend ActiveSupport::Concern

  included do
    # since reformatting how phone numbers are dealt with this has become redundant
    # def number_formatted(contact_type)
    #   number = send(contact_type)&.gsub(/[^0-9+]/, '')
    #   return "+91#{number}" unless number&.first == '+' || number.blank?

    #   number
    # end

    # def whatsapp_messaging_number
    #   # #find returns first element meeting block condition
    #   [number_formatted('whatsapp'), number_formatted('phone')].find(&:present?)
    # end

    def whatsapp_messaging_number
      # #find returns first element meeting block condition
      # Instructor has no phone attribute hence extra code
      [send('whatsapp'), respond_to?(:phone) ? send('phone') : nil].find(&:present?)
    end
  end
end
