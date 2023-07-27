module PasswordWizard
  extend ActiveSupport::Concern
  included do
    def self.password_wizard(n)
      # I character appears ambiguous in whatsapp text. Avoid confusion by removing
      ('A'..'L').reject { |letter| letter == 'I' }
                .concat(('m'..'z').to_a)
                .concat((1..9).to_a)
                .concat((1..9).to_a).sample(n).join
    end
  end
end
