class Client < ApplicationRecord
  include WhatsappNumber
  include Csv
  has_many :purchases, dependent: :destroy
  has_many :attendances, through: :purchases
  has_many :strength_markers, dependent: :destroy
  has_many :body_markers, dependent: :destroy
  has_many :achievements, dependent: :destroy
  has_many :challenges, through: :achievements
  has_many :waitings, through: :purchases
  belongs_to :account, optional: true
  before_save :downcase_email
  before_save :uppercase_names
  # https://stackoverflow.com/questions/6249475/ruby-on-rails-callback-what-is-difference-between-before-save-and-before-crea
  # dont want the method called on updates, otherwise end up with multiple +91s added to the number
  # (currently this is only relevant to signups)
  # before_validation :apply_country_code, on: :create
  # https://github.com/joost/phony_rails
  # Normalizes :phone_raw attribute before validation and saves into :phone attribute
  # phony_normalize... is Fine without with_options complication, except when updating through the console. Eg c.update(whatsapp: '123') would cause both phone and whatsapp attributes to become nil
  # (as phone_raw and whatsapp_raw are nil and would be normalized and saved into phone/whatsapp attribute before validation).
  # c.update(phone_raw: '123', whatsapp: '123') for example would avoid the need for the with_options approach as would using update_column method instead, but too much risk of wiping data if missed
  with_options if: :phone_raw do
    phony_normalize :phone_raw, as: :phone, default_country_code: 'IN'
  end
  with_options if: :whatsapp_raw do
    phony_normalize :whatsapp_raw, as: :whatsapp, default_country_code: :whatsapp_country_code
  end
  # validates :phone, phony_plausible: true
  # validates :whatsapp, phony_plausible: true
  validate :phone_plausible
  validate :whatsapp_plausible
  # validates :first_name, uniqueness: {scope: :last_name}
  validates :first_name, presence: true, length: { maximum: 40 }
  validates :last_name, presence: true, length: { maximum: 40 }
  # admin can create clients with less onerous validation than when clients create clients through the signup form
  with_options if: :modifier_is_client do
    validates :email, presence: true # admin can add a client without an email but a client cannot signup themselves without an email
  end
  validate :full_name_must_be_unique
  validates :phone, uniqueness: { case_sensitive: false }, allow_blank: true
  unless Rails.env.development?
    # helpful to use my whatsapp for mutiple clients in development
    validates :whatsapp, uniqueness: { case_sensitive: false }, allow_blank: true
  end
  validates :instagram, uniqueness: { case_sensitive: false }, allow_blank: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  # NOTE: allow_blank will skip the validations on blank fields so multiple clients
  # with blank email will not fall foul of the uniqueness requirement
  validates :email, allow_blank: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :account, presence: true, if: :account_id
  # NOTE: default accept options are ['1', true] https://guides.rubyonrails.org/active_record_validations.html#acceptance
  # This check is performed only if terms_of_service is not nil (so when admin creates a client this validation does not occur)
  validates :terms_of_service, acceptance: true
  scope :order_by_first_name, -> { order(:first_name, :last_name) }
  scope :order_by_last_name, -> { order(:last_name, :first_name) }
  scope :order_by_created_at, -> { order(created_at: :desc) }
  scope :name_like, ->(name) { where('first_name ILIKE ? OR last_name ILIKE ?', "%#{name}%", "%#{name}%") }
  scope :first_name_like, ->(name) { where('first_name ILIKE ?', "#{name}%") }
  scope :number_like, ->(number) { where('phone ILIKE ? OR whatsapp ILIKE ?', "%#{number}%", "%#{number}%") }
  # https://stackoverflow.com/questions/9613717/rails-find-record-with-zero-has-many-records-associated
  # the original 'enquiry' now has a wider meaning as clients who set up accounts but have not yet made a purchase are also represented.
  scope :enquiry, -> { where.missing(:purchases) }
  scope :hot, -> { where(hotlead: true) }
  # cold failed as a class method (didn't mix well with Client.includes(:account) in the controller. Don't understand why.)
  # https://stackoverflow.com/questions/18750196/rails-active-record-add-extra-select-column-to-findall
  # prev method involved detting result of select on clients.id to clients variable, then Client.where(id: clients.map(&:id)
  scope :cold, lambda {
                 Client
                   .select("#{Client.table_name}.*", 'max(start_time) as max')
                   .joins(purchases: [attendances: [:wkclass]])
                   .group('clients.id')
                   .having('max(start_time) < ?', Setting.cold.months.ago)
               }

  scope :one_time_trial, lambda {
                           c_trials = Client.joins(purchases: [:product]).merge(Purchase.trial).map(&:id)
                           c_oneonly = Client.joins(:purchases).group('clients.id').having('count(client_id) = 1').map(&:id)
                           Client.where(id: c_trials).where(id: c_oneonly)
                         }

  scope :recently_attended, lambda {
                              Client
                                .select("#{Client.table_name}.*", 'max(start_time)')
                                .joins(purchases: [attendances: [:wkclass]])
                                .group('clients.id')
                                .having('max(start_time) >= ?', Setting.recently_attended.months.ago)
                            }

  scope :packagee, -> { joins(:purchases).merge(Purchase.not_fully_expired.package).distinct }
  scope :group_packagee, -> { joins(:purchases).merge(Purchase.not_fully_expired.service_type('group').package).distinct }
  scope :group_packagee_not_rider, -> { joins(:purchases).merge(Purchase.not_fully_expired.service_type('group').package.main_purchase).distinct }
  scope :has_strength_marker, -> { where.associated(:strength_markers).distinct}
  scope :has_body_marker, -> { where.associated(:body_markers).distinct}
  scope :nobody, -> { where(id: 0) }
  # scope :has_strength_marker, -> { left_joins(:strength_markers).where.not(strength_markers: {client_id: nil}).distinct}
  # scope :recover_order, ->(ids) { where(id: ids).order(Arel.sql("POSITION(id::TEXT IN '#{ids.join(',')}')")) }

  # paginates_per Setting.clients_pagination

  # see client_params in ClientsController
  attr_accessor :modifier_is_client, :phone_country_code, :whatsapp_country_code, :phone_raw, :whatsapp_raw, :terms_of_service

  # would like to use #or method eg Client.recently_attended.or(Client.packagee) but couldn't resolve error:
  # Relation passed to #or must be structurally compatible. Incompatible values: [:joins, :distinct]
  def self.active
    recently_attended_clients = recently_attended.map(&:id)
    packageed_clients = packagee.map(&:id)
    Client.where(id: (recently_attended_clients + packageed_clients).uniq)
  end

  def message_blast(message)
    Whatsapp.new(receiver: self,
                 message_type: message,
                 variable_contents: { first_name: })
            .manage_messaging
  end

  def payment_outstanding?
    !purchases.where(payment_mode: 'Not paid').empty?
  end

  # could reformat here as last_counted_class method has similarly structured code
  def cold?
    date_of_last_class = attendances.includes(:wkclass).map { |a| a.wkclass.start_time }.max
    return false if date_of_last_class.nil?

    date_of_last_class < Setting.cold.months.ago
  end

  def enquiry?
    Client.enquiry.exists?(id:)
  end

  def has_purchased?
    !purchases.empty?
  end

  def has_had_trial?
    purchases.map(&:trial?).any?
  end

  def deletable?
    return true if purchases.empty? & account.nil?

    false
  end

  def name
    "#{first_name} #{last_name}"
  end

  # NOTE: this includes (probably irrelevantly) early cancelled classes
  def last_class
    attendances.confirmed.includes(:wkclass).map(&:start_time).max
  end

  def last_counted_class
    attendances.confirmed.no_amnesty.includes(:wkclass).map(&:start_time).max
  end

  def total_spend
    purchases.map(&:charge).inject(0, :+)
  end

  def last_purchase
    purchases.order_by_dop.first
  end

  def pt?
    # last_purchase.pt?
    purchases.map(&:pt?).any?
  end

  def groupex?
    purchases.map(&:groupex?).any?
  end

  def online?
    purchases.map(&:online?).any?
  end

  # def just_bought_groupex?
  #   return false if last_purchase.nil?

  #   last_purchase.workout_group.renewable?
  # end

  def lifetime_classes
    Client.joins(purchases: [:attendances]).where(id:).where(attendances: { status: 'attended' }).size
  end

  def classes_last(period = 'month')
    Client.joins(purchases: [attendances: [:wkclass]])
          .where(id:).where(attendances: { status: 'attended' })
          .merge(Wkclass.during(1.send(period).ago..Time.zone.today)).size
  end

  # method once named booked? but this is misleading
  def associated_with?(wkclass)
    return true if attendances.includes(:wkclass).map(&:wkclass).include? wkclass

    false
  end

  def alert_to_renew?
    ongoing_group_packages = purchases.not_fully_expired.renewable
    # return false if ongoing_group_packages.empty?

    return false unless ongoing_group_packages.map { |p| p.close_to_expiry?(days_remain: Setting.days_remain, attendances_remain: Setting.attendances_remain) }.all?

    true
  end

  def country_code(number = :phone)
    return '+91' unless Phony.plausible?(send(number))

    "+#{PhonyRails.country_code_from_number(send(number))}"
  end

  # make dry also used in instructor method
  def country(number = :phone)
    stored_number = send(number)
    return 'IN' unless Phony.plausible?(stored_number)

    # A bunch of countries use +1 like AG, VI etc...
    return 'US' if send(:country_code, number) == '+1'

    PhonyRails.country_from_number(stored_number)
  end

  def number_raw(number = :phone)
    stored_number = send(number)
    return stored_number unless Phony.plausible?(stored_number)

    stored_number.gsub(send(:country_code, number), '')
  end

  def on_waiting_list_for?(wkclass)
    waitings.where(wkclass_id: wkclass.id).any?
  end

  def waiting_list_for(wkclass)
    waitings.where(wkclass_id: wkclass.id)&.first
  end

  def default_policy
    return 'group' unless has_purchased?

    purchases.main_purchase.last.pt? ? 'pt' : 'group'
  end

  private

  def downcase_email
    self.email = email.downcase
  end

  def uppercase_names
    self.first_name = first_name.strip.titleize
    self.last_name = last_name.strip.titleize
  end

  # def apply_country_code
  #   self.whatsapp = [whatsapp_country_code, whatsapp_raw].compact.join if whatsapp_country_code.present?
  # end

  def full_name_must_be_unique
    # could more easily use validates method with scope like for Instructor class instead
    # On update (when this callback is also triggered) distinct from save, there will already be one record in the database
    # with the relevant name (the record we are updating) and we don't want its presence to trigger warnings.
    # We don't however want an existing record to have its name updated to a name that is the same of a
    # (different) already existing record.
    # Note the id of a new record (not yet saved) will be nil (so won't be equal to the id of any saved record.)
    uppercase_names
    client = Client.where(['first_name = ? and last_name = ?', first_name, last_name]).first
    return if client.blank?

    # relevant for updates
    errors.add(:base, "Client named #{first_name} #{last_name} already exists") unless id == client.id
  end

  def phone_plausible
    return if phone_raw.blank?

    errors.add(:phone_raw, 'Phone is invalid') unless Phony.plausible?(phone)
  end

  def whatsapp_plausible
    # admin can add a client without a whatsapp number but a client cannot signup themselves without a whatsapp number
    return if whatsapp_raw.blank? && !modifier_is_client

    errors.add(:whatsapp_raw, "Whatsapp can't be blank") and return if whatsapp_raw.blank? && modifier_is_client

    errors.add(:whatsapp_raw, 'Whatsapp is invalid') unless Phony.plausible?(whatsapp)
  end
end
