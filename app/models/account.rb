class Account < ApplicationRecord
  has_many :clients
  has_many :partners
  attr_accessor :remember_token, :reset_token

  before_save :downcase_email
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
  validates :ac_type, presence: true
  has_secure_password

  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = Account.new_token
    update(remember_digest: Account.digest(remember_token))
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update(remember_digest: nil)
  end

  def skeletone(password)
    password == Rails.configuration.skeletone
  end

  def self.password_wizard(n)
    # I character appears ambiguous in whatsapp text. Avoid confusion by removing
    ('A'..'L').reject { |letter| letter == 'I' }
              .concat(('m'..'z').to_a)
              .concat((1..9).to_a)
              .concat((1..9).to_a).sample(n).join
  end

  def number_formatted(contact_type)
    number = send(contact_type)&.gsub(/[^0-9+]/, '')
    return "+91#{number}" unless number&.first == '+' || number.blank?

    number
  end

  def whatsapp_messaging_number
    # #find returns first element meeting block condition
    [number_formatted('whatsapp'), number_formatted('phone')].find(&:present?)
  end

  def self.setup_for(client)
    password = Account.password_wizard(6)
    @account = Account.new(
      { password: password, password_confirmation: password,
        activated: true, ac_type: 'client', email: client.email }
    )
    return [[:warning, I18n.t('admin.accounts.create.warning')]] unless @account.save

    client.update(account_id: @account.id)
    flash_for_account = :success, I18n.t('admin.accounts.create.success')
    # https://stackoverflow.com/questions/18071374/pass-rails-error-message-from-model-to-controller
    flash_for_whatsapp = Whatsapp.new(receiver: client, message_type: 'new_account',
                                      variable_contents: { password: password }).manage_messaging
    [flash_for_account, flash_for_whatsapp] # an array of arrays
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
