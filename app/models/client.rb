class Client < ApplicationRecord
  include WhatsappNumber
  include Csv
  has_many :purchases, dependent: :destroy
  has_many :attendances, through: :purchases
  belongs_to :account, optional: true
  before_save :downcase_email
  # validates :first_name, uniqueness: {scope: :last_name}
  validates :first_name, presence: true, length: { maximum: 40 }
  validates :last_name, presence: true, length: { maximum: 40 }
  validate :full_name_must_be_unique
  validates :phone, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :whatsapp, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :instagram, uniqueness: { case_sensitive: false }, allow_blank: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  # NOTE: allow_blank will skip the validations on blank fields so multiple clients
  # with blank email will not fall foul of the uniqueness requirement
  validates :email, allow_blank: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :account, presence: true, if: :account_id
  scope :order_by_first_name, -> { order(:first_name, :last_name) }
  scope :order_by_last_name, -> { order(:last_name, :first_name) }
  scope :order_by_created_at, -> { order(created_at: :desc) }
  scope :name_like, ->(name) { where('first_name ILIKE ? OR last_name ILIKE ?', "%#{name}%", "%#{name}%") }
  # https://stackoverflow.com/questions/9613717/rails-find-record-with-zero-has-many-records-associated
  scope :enquiry, -> { left_outer_joins(:purchases).where(purchases: { id: nil }) }
  scope :hot, -> { where(hotlead: true) }
  # cold failed as a class method (didn't mix well with Client.includes(:account) in the controller. Don't understand why.)
  # https://stackoverflow.com/questions/18750196/rails-active-record-add-extra-select-column-to-findall
  # prev method involved detting result of select on clients.id to clients variable, then Client.where(id: clients.map(&:id)
  scope :cold, lambda {
                 Client
                   .select("#{Client.table_name}.*", 'max(start_time) as max')
                   .joins(purchases: [attendances: [:wkclass]])
                   .group('clients.id')
                   .having('max(start_time) < ?', 3.months.ago)
               }

  scope :recently_attended, lambda {
                 Client
                   .select("#{Client.table_name}.*", 'max(start_time) as max')
                   .joins(purchases: [attendances: [:wkclass]])
                   .group('clients.id')
                   .having('max(start_time) >= ?', 3.months.ago)
               }

  scope :packagee, -> { joins(:purchases).merge(Purchase.not_fully_expired.package).distinct }

  paginates_per 20

  # would like to use #or method eg Client.recently_attended.or(Client.packagee) but couldn't resolve error:
  # Relation passed to #or must be structurally compatible. Incompatible values: [:joins, :distinct]
  def self.active
    recently_attended_clients = Client.recently_attended.map(&:id)
    packageed_clients = Client.packagee.map(&:id)
    Client.where(id: (recently_attended_clients + packageed_clients).uniq)
  end

  def message_blast(message)
    Whatsapp.new(:receiver => self,
                 :message_type => message,
                 :variable_contents => {:first_name => self.first_name})
                 .manage_messaging
  end

  def cold?
    date_of_last_class = attendances.includes(:wkclass).map { |a| a.wkclass.start_time }.max
    return false if date_of_last_class.nil?

    date_of_last_class < 3.months.ago
  end

  def enquiry?
    Client.enquiry.exists?(id: id)
  end

  def name
    "#{first_name} #{last_name}"
  end

  def last_class
    attendances.confirmed.includes(:wkclass).map(&:start_time).max
  end

  def total_spend
    purchases.map(&:payment).inject(0, :+)
  end

  def last_purchase
    purchases.order_by_dop.first
  end

  def pt?
    last_purchase.pt?
  end

  def groupex?
    !last_purchase.pt?
  end

  def lifetime_classes
    Client.joins(purchases: [:attendances]).where(id: id).where(attendances: { status: 'attended' }).size
  end

  def classes_last(period = 'month')
    Client.joins(purchases: [attendances: [:wkclass]])
          .where(id: id).where(attendances: { status: 'attended' })
          .merge(Wkclass.during(1.send(period).ago..Time.zone.today)).size
  end

  def booked?(wkclass)
    return true if attendances.includes(:wkclass).map(&:wkclass).include? wkclass

    return false
  end

  private

  def downcase_email
    self.email = email.downcase
  end

  def full_name_must_be_unique
    # complicated due to situation on update.
    # [not particulary complicated now with reformatting]
    # There will of course be one record in the database
    # with the relevant name on update (the record we are updating) and we don't want its presence
    # to trigger warnings. We don't however want an exisitng record to have its name changed to
    # a name that is the same of a (different) already existing record. Note the id of a new record
    # (not yet saved) will be nil (so won't be equal to the id of any saved record.)
    client = Client.where(['first_name = ? and last_name = ?', first_name, last_name]).first
    return if client.blank?

    # relevant for updates
    errors.add(:base, "Client named #{first_name} #{last_name} already exists") unless id == client.id
  end
end
