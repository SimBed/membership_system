class Account < ApplicationRecord
  has_one :client
  has_one :partner
  has_many :orders
  has_one :instructor
  has_many :assignments, dependent: :destroy
  has_many :roles, through: :assignments
  attr_accessor :remember_token, :reset_token, :current_role

  before_save :downcase_email
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }
  validates :ac_type, presence: true
  has_secure_password
  scope :has_role, ->(*role) { joins(assignments: [:role]).where(role: { name: [role] }).distinct }
  # scope :order_by_ac_type, -> { order(:ac_type, :email) }

  # not yet used
  def has_role?(*role)
    # #& is Array class's intersection method
    # to_a won't convert string to array , but can achieve the same with splat operator or Array.wrap()
    # https://medium.com/rubycademy/3-safe-ways-to-convert-values-into-array-in-ruby-c3990a5223ef
    # splat in argument and to_s in method means argument can be a single symbol/string or a comma separted list of symbols/strings
    (roles.pluck(:name) & role.map(&:to_s)).any?
  end

  def priority_role
    roles.order(:view_priority).first
  end

  def without_purchase?
    client.purchases.empty? if client
  end

  def clean_up
    # reformat
    case ac_type
    when 'client'
      client.update(account_id: nil)
    when 'instructor'
      instructor.update(account_id: nil)
    when 'partner'
      partner.update(account_id: nil)
    end
    destroy
  end

  def self.digest(string)
    cost = if ActiveModel::SecurePassword.min_cost
             BCrypt::Engine::MIN_COST
           else
             BCrypt::Engine.cost
           end
    BCrypt::Password.create(string, cost:)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = Account.new_token
    # update(remember_digest: Account.digest(remember_token))
    update_column(:remember_digest, Account.digest(remember_token))
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    # update(remember_digest: nil)
    update_column(:remember_digest, nil)
  end

  def skeletone(password)
    password == Rails.configuration.skeletone
  end

  def self.setup_for(client)
    account_params = { email: client.email,
                       ac_type: 'client',
                       account_holder: client }
    result = AccountCreator.new(account_params).create
    if result.success?
      flash_for_account = :success, I18n.t('admin.accounts.create.success')
      # https://stackoverflow.com/questions/18071374/pass-rails-error-message-from-model-to-controller
      flash_for_whatsapp = Whatsapp.new(receiver: client, message_type: 'new_account',
                                        variable_contents: { password: result.password }).manage_messaging
      [flash_for_account, flash_for_whatsapp] # an array of arrays
    else
      [:warning, I18n.t('admin.accounts.create.warning')]
    end
  end

  def create_reset_digest
    self.reset_token = Account.new_token
    update_columns(reset_digest: Account.digest(reset_token), reset_sent_at: Time.zone.now)
    # update_column(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
    AccountMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
