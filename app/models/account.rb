class Account < ApplicationRecord
  has_many :clients
  has_many :partners
  attr_accessor :remember_token, :reset_token

  before_save :downcase_email
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i.freeze
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

  private

  def downcase_email
    self.email = email.downcase
  end
end
