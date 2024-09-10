class Account < ApplicationRecord
  # dependent option controls what happens to the associated objects when their owner is destroyed (a client can survive wihtout an account)
  has_one :client, dependent: nil
  has_one :instructor, dependent: nil
  # has_many :orders, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :logins, dependent: :destroy
  has_many :roles, through: :assignments
  attr_accessor :remember_token, :reset_token, :current_role

  before_save :downcase_email
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 }
  has_secure_password
  scope :has_role, ->(*role) { joins(assignments: [:role]).where(role: { name: [role] }).distinct }

  # not yet used
  def has_role?(*role_name)
    # #& is Array class's intersection method
    # to_a won't convert string to array, but can achieve the same with splat operator or Array.wrap()
    # https://medium.com/rubycademy/3-safe-ways-to-convert-values-into-array-in-ruby-c3990a5223ef
    # splat in argument and to_s in method means argument can be a single symbol/string or a comma separted list of symbols/strings
    # (roles.pluck(:name) & role.map(&:to_s)).any?
    # and Style Guide preference
    roles.pluck(:name).intersect?(role_name.map(&:to_s))
  end

  def priority_role
    roles.order(:view_priority).first
  end

  def multiple_roles?
    roles.size > 1
  end

  def client_only?
    # avoid anyone messing with triggering password resets for non-client emails
    has_role?('client') && !multiple_roles?
  end

  def without_purchase?
    client.purchases.empty? if client
  end

  def clean_up
    Role.not_including('client', 'superadmin', 'admin').each  do |role| # As there is an Admin:Module (not Admin Model), Active.exists? would give NoMethodError: undefined method `exists?' for Admin:Module
      model_name = role.name.camelcase.safe_constantize # so nil for 'junioradmin' (as no Junioradmin model) and Instructor for 'instructor'
      model_name.update(account_id: nil) if model_name&.exists? && has_role?(role.name) 
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
    update_column(:remember_digest, Account.digest(remember_token))
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?

    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_column(:remember_digest, nil)
  end

  def skeletone(password)
    password == Rails.configuration.skeletone
  end

  def self.setup_for(client)
    account_params = { email: client.email,
                       role_name: 'client',
                       account_holder: client }
    outcome = AccountCreator.new(account_params).create
    if outcome.success?
      flash_for_account = :success, I18n.t('admin.accounts.create.success')
      # https://stackoverflow.com/questions/18071374/pass-rails-error-message-from-model-to-controller
      flash_for_whatsapp = Whatsapp.new(receiver: client, message_type: 'new_account',
                                        variable_contents: { password: outcome.password }).manage_messaging
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

  def last_login_date
    return nil if logins.empty?

    logins.order_by_recent_first.first.created_at
  end  

  private

  def downcase_email
    self.email = email.downcase
  end
end
