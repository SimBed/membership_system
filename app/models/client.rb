class Client < ApplicationRecord
  include WhatsappNumber
  include Csv
  has_many :purchases, dependent: :destroy
  has_many :attendances, through: :purchases
  belongs_to :account, optional: true
  before_save :downcase_email
  before_save :uppercase_names
  # https://stackoverflow.com/questions/6249475/ruby-on-rails-callback-what-is-difference-between-before-save-and-before-crea
  # dont want the method called on updates, otherwaie end up with multiple +91s added to the number
  before_validation :apply_country_code, on: :create  
  # validates :first_name, uniqueness: {scope: :last_name}
  validates :first_name, presence: true, length: { maximum: 40 }
  validates :last_name, presence: true, length: { maximum: 40 }
  # admin can create clients with less onerous validation than when clients create clients through the signup form
  with_options unless: :modifier_is_admin do
    validates :email, presence: true
  end
  validate :full_name_must_be_unique
  unless Rails.env.development?
    # helpful to use my phone number for mutiple clients in development
    validates :phone, uniqueness: { case_sensitive: false }, allow_blank: true
  end
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
  # the original 'enquiry' now has a wider meaning as clients who set up accounts but have not yet made a purchase are also represented.
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
               
  scope :one_time_trial, lambda {
                c_trials= Client.joins(purchases: [:product]).merge(Purchase.trial).map(&:id)
                c_oneonly =  Client.joins(:purchases).group('clients.id').having('count(client_id) = 1').map(&:id)
                Client.where(id: c_trials).where(id: c_oneonly)
               }

  scope :recently_attended, lambda {
                 Client
                   .select("#{Client.table_name}.*", 'max(start_time)')
                   .joins(purchases: [attendances: [:wkclass]])
                   .group('clients.id')
                   .having('max(start_time) >= ?', 3.months.ago)
               }

  scope :packagee, -> { joins(:purchases).merge(Purchase.not_fully_expired.package).distinct }

  paginates_per 50

  # see client_params in ClientsController
  attr_accessor :modifier_is_admin, :whatsapp_country_code

  # would like to use #or method eg Client.recently_attended.or(Client.packagee) but couldn't resolve error:
  # Relation passed to #or must be structurally compatible. Incompatible values: [:joins, :distinct]
  def self.active
    recently_attended_clients = recently_attended.map(&:id)
    packageed_clients = packagee.map(&:id)
    Client.where(id: (recently_attended_clients + packageed_clients).uniq)
  end

  def message_blast(message)
    Whatsapp.new(:receiver => self,
                 :message_type => message,
                 :variable_contents => {:first_name => self.first_name})
                 .manage_messaging
  end



  # def groupex_package_status
  #   groupex_package_purchases = purchases.package.order_by_dop.renewable
  #   return nil if groupex_package_purchases.empty? #new client
  #   ongoing_groupex_package_purchases = groupex_package_purchases.reject(&:expired?)

  # end

  def renewal # reformat/dry
    # groupex_package_purchases = purchases.package.order_by_dop.reject(&:pt?)
    groupex_package_purchases = purchases.package.order_by_dop.renewable
    return nil if groupex_package_purchases.empty? #new client

    unlimited3m = Product.where(max_classes: 1000, validity_length: 3, validity_unit: 'M').first
    ongoing_groupex_package_purchases = groupex_package_purchases.reject(&:expired?)
    if ongoing_groupex_package_purchases.empty?
      last_groupex_package_purchase = groupex_package_purchases.first
      if last_groupex_package_purchase.trial? # offer trials a discounted 3m unlimited
      # expired trial        
        renewal_price = unlimited3m.renewal_price("renewal_posttrial_expiry")
        base_price = unlimited3m.renewal_price("base")
        valid = !renewal_price.nil? && !base_price.nil?
        { ongoing: false, trial: true, product: unlimited3m, price: renewal_price, base_price: base_price, valid: valid, alert_to_renew?: true, renewal_offer: "renewal_posttrial_expiry" }
      else
      # expired package
        product = last_groupex_package_purchase.product
        renewal_price = product.renewal_price("base")
        valid = !renewal_price.nil?
        { ongoing: false, trial: false, product: product, price: renewal_price, valid: valid, alert_to_renew?: true, renewal_offer: "base" }
      end
    else
      ongoing_groupex_package_purchase = ongoing_groupex_package_purchases.first
      # if ongoing_groupex_package_purchase.name == 'Space Group UC:1W'
      if ongoing_groupex_package_purchase.trial?
        # ongoing trial
        renewal_price = unlimited3m.renewal_price("renewal_pretrial_expiry")
        base_price = unlimited3m.renewal_price("base")
        valid = !renewal_price.nil? && !base_price.nil?
        { ongoing: true, trial: true, product: unlimited3m, price: renewal_price, base_price: base_price, valid: valid, alert_to_renew?: true, renewal_offer: "renewal_pretrial_expiry" }
      else
        # ongoing package
        product = ongoing_groupex_package_purchase.product
        # { ongoing: true, trial: false, product: product, price: product.renewal_price("10% pre-expiry Discount"), base_price: product.renewal_price("Base") }
        renewal_price = product.renewal_price("renewal_pre_expiry")
        base_price = product.renewal_price("base")
        valid = !renewal_price.nil? && !base_price.nil?
        { ongoing: true, trial: false, product: product, price: renewal_price, base_price: base_price, valid: valid, alert_to_renew?: alert_to_renew?, renewal_offer: "renewal_pre_expiry" }
      end
    end
  end

  def cold?
    date_of_last_class = attendances.includes(:wkclass).map { |a| a.wkclass.start_time }.max
    return false if date_of_last_class.nil?

    date_of_last_class < 3.months.ago
  end

  def enquiry?
    Client.enquiry.exists?(id: id)
  end

  def has_purchased?
    !purchases.size.zero?
  end

  def deletable?
    return true if purchases.empty? & account.nil?

    false
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

  def just_bought_groupex?
    return false if last_purchase.nil?
    
    last_purchase.workout_group.renewable?
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

  # not used
  def has_renewed?
    purchases.not_fully_expired.reject { |p| p.pt? }.size > 1
  end

  # not used
  # def recently_purchased?
  #   ongoing_group_packages = purchases.not_fully_expired.reject { |p| p.pt? || p.trial? }
  #   return false if ongoing_group_packages.empty?

  #   return true if ongoing_group_packages.max_by {|h| h.dop}.dop > 7.days.ago

  #   false
  # end

  # not used
  # def renewal_time?
  #   ongoing_group_packages = purchases.not_fully_expired.reject { |p| p.pt? || p.trial? }
  #   return false if ongoing_group_packages.empty?

  #   return true if ongoing_group_packages.select { |p| p.close_to_expiry? }.include?(true)

  #   false
  # end

  def alert_to_renew?
    ongoing_group_packages = purchases.not_fully_expired.renewable
    # return false if ongoing_group_packages.empty?

    return false unless ongoing_group_packages.map { |p| p.close_to_expiry?(days_remain: Setting.days_remain, attendances_remain: Setting.attendances_remain)}.all?

    true
  end


  private

  def downcase_email
    self.email = email.downcase
  end

  def uppercase_names
    # self.first_name = first_name.split.map(&:capitalize)
    self.first_name = first_name.titleize
    self.last_name = last_name.titleize
  end

  def apply_country_code
    self.whatsapp = [whatsapp_country_code, whatsapp].compact.join if self.whatsapp_country_code.present?
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
