class Purchase < ApplicationRecord
  include Csv
  belongs_to :product
  belongs_to :client
  belongs_to :fitternity, optional: true
  belongs_to :price
  has_many :attendances, dependent: :destroy
  # has_one :restart, dependent: :destroy
  has_one :restart_as_child, class_name: "Restart", foreign_key: "child_id", dependent: :destroy
  has_one :restart_as_parent, class_name: "Restart", foreign_key: "parent_id"
  has_one :child_purchase, through: :restart_as_parent, source: :child
  has_one :parent_purchase, through: :restart_as_child, source: :parent
  has_many :adjustments, dependent: :destroy
  has_many :freezes, dependent: :destroy
  has_many :penalties, dependent: :destroy
  has_many :discount_assignments, dependent: :destroy
  has_many :discounts, through: :discount_assignments
  has_many :waitings, dependent: :destroy
  # some pts are given a rider benefit of group classes
  has_one :rider_purchase, class_name: 'Purchase', dependent: :destroy # , foreign_key: "purchase_id"
  belongs_to :main_purchase, class_name: 'Purchase', foreign_key: 'purchase_id', optional: true
  has_one :payment, as: :payable, dependent: :destroy
	accepts_nested_attributes_for :payment
  before_save :set_sunset_date
  delegate :name, :workout_group, :dropin?, :trial?, :unlimited_package?, :fixed_package?, :product_type,
           :product_style, :pt?, :groupex?, :online?, :max_classes, :attendance_estimate, :rider?, to: :product
  validates :charge, presence: true
  validates :payment_mode, presence: true
  # validates :ar_payment, presence: true, if: :adjust_restart?
  # with_options if: :adjust_restart? do
  #   validates :ar_payment, presence: true
  #   validates :ar_date, presence: true
  # end
  validate :check_if_already_had_trial
  validate :payment_amount_equals_charge
  # Fitternity redundant now
  # validates :fitternity, presence: true, if: :fitternity_id
  # validate :fitternity_payment
  # Fitternity redundant now and this validation prevented bulk setting of sunset_dates
  # validate :fitternity_ongoing_package
  scope :not_expired, lambda {
                        where.not(status: ['expired', 'classes all booked'])
                      }
  scope :not_fully_expired, -> { where.not(status: 'expired') }
  scope :fully_expired, -> { where(status: 'expired') }
  # simple solution using distinct (more complex variants) courtesy of Yuri Karpovich https://stackoverflow.com/questions/20183710/find-all-records-which-have-a-count-of-an-association-greater-than-zero
  # scope :started, -> { joins(:attendances).merge(Attendance.no_amnesty).distinct }
  scope :started, -> { where.not(status: 'not started') }
  scope :not_started, -> { where(status: 'not started') }
  # 'using a scope through an association'
  # https://apidock.com/rails/ActiveRecord/SpawnMethods/merge
  scope :package, -> { joins(:product).merge(Product.package) }
  scope :package_not_trial, -> { joins(:product).merge(Product.package_not_trial) }
  scope :unlimited, -> { joins(:product).merge(Product.unlimited) }
  scope :dropin, -> { joins(:product).merge(Product.dropin) }
  scope :fixed, -> { joins(:product).merge(Product.fixed) }
  scope :trial, -> { joins(:product).merge(Product.trial) }
  # scope :sunset_passed, -> { where(sunset_date: (Date.today..Date.Infinity.new)) }
  scope :sunset_passed, -> { not_fully_expired.where('sunset_date < ?', Time.zone.today).order(:sunset_date) }
  scope :package_started_not_expired, -> { package.started.not_expired }
  scope :package_started_not_fully_expired, -> { package.started.not_fully_expired }
  scope :renewable, -> { joins(product: [:workout_group]).where(workout_groups: { renewable: true }) }
  # wg is an array of workout group names
  # see 3.3.3 subset conditions https://guides.rubyonrails.org/active_record_querying.html#pure-string-conditions
  scope :workout_group, ->(wg) { joins(product: [:workout_group]).where(workout_groups: { name: wg }) }
  # stata is an array of purchases statuses
  scope :statuses, ->(stata) { where(status: stata) }
  # alternative 'mixes concerns and logic'
  # scope :package, -> { joins(:product).where("max_classes > 1") }
  scope :order_by_client_dop, -> { joins(:client).order(:first_name, dop: :desc) }
  scope :order_by_dop, -> { order(dop: :desc, created_at: :desc) }
  scope :order_by_expiry_date, -> { order(expiry_date: :desc) }
  # scope :order_by_expiry_date, -> { package_started_not_expired.order(:expiry_date) }
  scope :client_name_like, ->(name) { joins(:client).merge(Client.name_like(name)) }
  # scope :uninvoiced, lambda {
  #                      package.where(invoice: nil).joins(product: [:workout_group])
  #                             .where(workout_groups: { requires_invoice: true })
  #                    }
  scope :service_type, ->(service) { joins(product: [:workout_group]).where(workout_groups: { service: }) }
  scope :unpaid, -> { where(payment_mode: 'Not paid') }
  scope :written_off, -> { where(payment_mode: 'Write Off') }
  scope :classpass, -> { where(payment_mode: 'ClassPass') }
  scope :close_to_expiry, -> { package_started_not_expired.select(&:close_to_expiry?) }
  scope :remind_to_renew, -> { package_started_not_expired.select(&:remind_to_renew?) }
  scope :during, ->(period) { where(dop: period) }
  scope :unexpired_rider_without_ongoing_main, -> { not_fully_expired.joins(:main_purchase).where.not(main_purchase: { status: ['ongoing', 'classes all booked'] }) }
  scope :rider, -> { where.not(purchase_id: nil) }
  scope :main_purchase, -> { where(purchase_id: nil) }
  scope :expired_in, ->(period) { where(expiry_date: period) }
  # no guarantee the natural expiry was not on the sunset date but highly unlikely (we do not record that a package ahas been actively sunset). 
  scope :sunsetted, -> { where('sunset_date=expiry_date')}
  # used in Purchases controller's handle_sort method
  # raw SQL in Active Record functions will give an error to guard against SQL injection
  # in the case where the raw SQl contains user input i.e. a params value
  # the error can be overriden by converting the raw SQL string literals to an Arel::Nodes::SqlLiteral object.
  # there is no user input in the converted Arel object, so this is OK
  # 'id:: text' is equivalent to 'CAST (id AS TEXT)' see https://www.postgresqltutorial.com/postgresql-cast/
  # position is a Postgresql string function, see https://www.postgresqltutorial.com/postgresql-position/
  scope :recover_order, ->(ids) { where(id: ids).order(Arel.sql("POSITION(id::TEXT IN '#{ids.join(',')}')")) }

  attr_accessor :renewal_discount_id, :status_discount_id, :oneoff_discount_id, :commercial_discount_id, :discretion_discount_id, :base_price

  def self.next(purchase, key = :created_at)
    self.where("#{key} > ?", purchase.send(key)).first
  end

  def restart_payment
    group_drop_in_price = Product.current.dropin.space_group.first.base_price_at(Time.zone.now).price
    [attendances.no_amnesty.size * group_drop_in_price, Setting.restart_min_charge].max
  end

  def can_restart?
    return false unless groupex? && ongoing? && !dropin? && !trial? && !rider?

    # NOTE: the new restarted package can itself be restarted (but obviously the original package can only be restarted once) 
    return false if restart_as_parent || restart_payment > charge

    true
  end

  def restart_warning?
    return false unless can_restart?

    days_until_sunset = (Time.zone.today.beginning_of_day.to_date..sunset_date.end_of_day).count
    product_duration_days = product.duration.in_days
    return true if product_duration_days > days_until_sunset

    false
  end

  def discount(base_price, *discounts)
    discounts.each do |discount|
      base_price = (base_price * (1 - (discount.percent.to_f / 100))) - discount.fixed
    end
  end

  def deletable?
    return true if attendances.empty? && freezes.empty? && adjustments.empty?

    false
  end

  # method allows for 'booking' onto waiting list ie restricted: false (ok to join a waiting list if booked for another class at same time)
  def self.available_for_booking(wkclass, client = nil, restricted: true)
    purchases = client.nil? ? available_to(wkclass) : available_to(wkclass).where(client_id: client.id)
    purchases = purchases.reject do |p|
      p.purchased_after?(wkclass.start_time.to_date) ||
        p.expires_before?(wkclass.start_time.to_date) ||
        p.already_used_for?(wkclass)
    end
    purchases = purchases.reject { |p| (p.committed_on?(wkclass.start_time.to_date) && wkclass.workout.limited?) } if restricted
    purchases
  end

  # e.g. [["Aparna Shah 9C:5W Feb 12", 1], ["Aryan Agarwal UC:3M Jan 31", 2, {class: "close_to_expiry"}], ...]
  # used in attendances controller to populate dropdown for new booking
  def self.qualifying_purchases(wkclass)
    available_for_booking(wkclass).map do |p|
      date_if_multiple_purchases = p.dop.strftime('%b %d') if p.client.purchases.not_expired.size > 1
      ["#{p.client.first_name} #{p.client.last_name} #{p.name} #{date_if_multiple_purchases}", p.id]
    end
  end

  def self.use_for_booking(wkclass, client, restricted: true)
    # in unusual case of more than one available purchase, use the started one (earliest dop if 2 started ones) or the earliest dop if no started one
    purchases = available_for_booking(wkclass, client, restricted: restricted)
    return purchases.first if purchases.size < 2

    started_purchases = purchases.reject(&:not_started?)
    started_purchases.empty? ? purchases.first : started_purchases.first
  end

  def self.by_product_date(product_id, period)
    joins(:product)
      .where(dop: period)
      .where(products: { id: product_id.to_s })
      .order(dop: :desc)
  end

  def committed_on?(adate)
    return false if fixed_package? # fixed packages can do what they want (except book the same class twice!)

    # committed if attendance on same day (but ignore Open Gym attendances (ie workouts that are not limited ))
    attendances.committed.includes(:wkclass).map { |a| a.wkclass.workout.limited ? a.start_time.to_date : nil }.include?(adate)
  end

  def restricted_on?(wkclass)
    return false unless wkclass.workout.limited? # open gym can be booked even if another class is booked on same day

    return false if fixed_package? # fixed packages can do what they want (except book the same class twice!)

    attendances.committed.includes(:wkclass).reject { |a| a.wkclass == wkclass || !a.wkclass.workout.limited }
               .map { |a| a.start_time.to_date }
               .include?(wkclass.start_time.to_date)
  end

  def already_used_for?(wkclass)
    return true if wkclass.purchases.include? self

    false
  end

  def already_booked_for?(wkclass)
    return true if attendances.committed.where(wkclass_id: wkclass.id).any?

    false
  end

  def purchased_after?(adate)
    dop > adate
  end

  def expires_before?(wkclass_date)
    return false if expiry_date.nil?

    expiry_date < wkclass_date
  end

  def name_with_dop
    "#{name} - #{dop.strftime('%d %b %y')}"
  end

  def status_calc
    return 'expired' if restart_as_parent

    return 'expired' if rider? && main_purchase.expired?

    status_hash = self.status_hash
    return 'not started' if status_hash[:attendance_provisional] == 'not started'
    return 'booked but not started' if status_hash[:attendance_provisional] == 'booked but not started'
    return 'expired' if status_hash[:attendance_confirmed] == 'exhausted' || status_hash[:validity] == 'expired'
    return 'classes all booked' if status_hash[:attendance_provisional] == 'exhausted'

    'ongoing'
  end

  def freezed?(adate)
    freezes.each do |f|
      return true if adate.between?(f.start_date, f.end_date.end_of_day)
    end
    false
  end

  def freezes_cover(adate)
    freezes.select { |f| adate.between?(f.start_date, f.end_date.end_of_day) }
  end

  def display_frozen?(adate)
    freezed?(adate) && !expired?
  end

  # for new freeze form in client booking page
  def new_freeze_dates
    next_month = Time.zone.tomorrow..Time.zone.today.advance(months: 1)
    next_month_restricted = next_month.to_a
    freezes.each { |freeze|
      next_month_restricted = next_month_restricted.without((freeze.start_date..freeze.end_date).to_a) if freeze.applies_during(next_month)
    }
    earliest = [next_month_restricted.first, expiry_date].min unless next_month_restricted.first.nil? # comparing nil directly against a date fails
    latest = [next_month_restricted.last, expiry_date].min unless next_month_restricted.last.nil?
    { earliest:, latest: }
  end

  def freeze_permitted?
    return false if expired? || not_started? || trial? || rider? || expiry_date&.today? || new_freeze_dates[:earliest].nil?

    true
  end

  # use for manually automating bulk freezes over holidays
  def freezes_cover?(period)
    freezes.map { |f| f.applies_during(period) }.any?
  end

  def expired?
    status == 'expired'
  end

  def not_started?
    status == 'not started'
  end

  def ongoing?
    status == 'ongoing'
  end

  def provisionally_expired?
    ['classes all booked'].include?(status)
  end

  def expired_in?(period)
    expired? && period.cover?(expiry_date)
  end

  def expiry_cause
    return unless expired?
    return 'restart' if restart_as_parent
    return 'used max classes' if attendances.no_amnesty.confirmed.size == max_classes
    return 'PT Package expired' if rider?
    return 'sunset' if expired_on == sunset_date

    'max time period'
  end

  def expired_on
    return unless expired?
    return restart_as_parent.payment.dop if restart_as_parent
    return max_class_expiry_date if attendances.no_amnesty.confirmed.size == max_classes
    # return main_purchase.expired_on if rider?

    expiry_date
  end

  def will_expire_on
    return nil unless provisionally_expired?

    attendances.no_amnesty.includes(:wkclass).map(&:start_time).max
  end

  def pt_will_expire_on
    return sunset_date if not_started?

    return expiry_date if attendances.no_amnesty.size < max_classes

    attendances.no_amnesty.joins(:wkclass).map(&:start_time).max
  end

  def expiry_date_calc
    return restart_as_parent.payment.dop if restart_as_parent

    return if attendances.no_amnesty.empty?

    # end_date formulae above overstate by 1 day so deduct 1
    # to_date changes ActiveSupport::TimeWithZone object to Date object
    # as 'Sun, 12 Dec 2021' preferred to 'Sun, 12 Dec 2021 10:30:00.000000000 UTC +00:00'
    (start_date + product.duration + extra_days - 1.day).to_date
  end

  def extra_days
    added_days = adjustments.map(&:adjustment).inject(0, :+).days
    frozen_days = freezes.map(&:duration).inject(0, :+).days
    penalty_days = penalties.map(&:amount).inject(0, :+).days
    added_days + frozen_days - penalty_days
  end

  def days_to_expiry
    if ['ongoing', 'booked but not started'].include?(status)
      (expiry_date - Time.zone.today).to_i
    else
      # random high number is useful for sorting by days to expiry
      1000
    end
  end

  def expiry_revenue
    return 0 unless expired?
    # individual fitternity packages are dummy packages for efficiency
    # either is ok, just extra failsafe to guard against admin error
    return 0 if payment_mode == 'Fitternity' # || price.name == 'Fitternity'

    attendance_revenue = attendances.includes(purchase: [:product]).confirmed.no_amnesty.map(&:revenue).inject(0, :+)
    # attendance revenue should never be more than payment, but if it somehow is, then it is consistent that expiry revenue should be negative
    return (charge - attendance_revenue) unless restart_as_parent
        
    restart_as_parent.payment.amount - attendance_revenue
  end

  def start_to_expiry
    status_hash[:attendance_provisional].tap do |aps|
      return aps if ['not started'].include? aps
    end
    return start_date.strftime('%d %b %y').to_s if dropin?

    "#{start_date.strftime('%d %b %y')} - #{expiry_date.strftime('%d %b %y')}"
  end

  def attendances_remain(provisional: true, unlimited_text: true)
    attendance_count = provisional ? attendances.no_amnesty.size : attendances.no_amnesty.confirmed.size
    return 'unlimited' if max_classes == 1000 && unlimited_text == true

    max_classes - attendance_count
  end

  # apply to ongoing packages. Not designed to work sensibly with an expired purchase
  def close_to_expiry?(days_remain: 5, attendances_remain: 2)
    return true if attendances_remain(unlimited_text: false) < attendances_remain || days_to_expiry < days_remain

    false
  end

  # keyword arguments changed in ruby 3
  # https://juanitofatas.com/ruby-3-keyword-arguments
  # Prefix argument with ** if you want to pass in keywords:
  def remind_to_renew?(days_remain: 5, attendances_remain: 2)
    keyword_args = { days_remain:, attendances_remain: }
    return true if close_to_expiry?(**keyword_args) && !renewed?

    false
  end

  def renewed?
    clients_ongoing_packages = client.purchases.main_purchase.package.not_fully_expired
    return true if clients_ongoing_packages.size > 1

    false
  end

  def start_date_calc
    attendances.no_amnesty.includes(:wkclass).map(&:start_time).min&.to_date
  end

  def sunset_date_calc
    product_duration = product.duration
    sunset_key = product_duration <= 7.days ? :week_or_less : :month_or_more
    dop + product_duration + Setting.sunset_limit_days[sunset_key].days
  end

  def sun_has_set?
    Time.zone.today > sunset_date
  end

  def sunset_action
    return :sunrise if expiry_cause == 'sunset' && status_calc != 'expired' # there should not be an option to sunrise a purchase that would otherwise be expired anyway
    return :sunset if sun_has_set? && !expired?

    nil
  end
  # rubocop advises Lint/IneffectiveAccessModifier: private does not make singleton methods private
  # https://stackoverflow.com/questions/4952980/how-to-create-a-private-class-method

  def self.available_to(wkclass)
    not_expired
      .joins(product: [:workout_group])
      .joins(:client)
      .merge(WorkoutGroup.includes_workout_of(wkclass))
      .includes(:client)
      .order('clients.first_name', 'purchases.dop')
  end

  private

  def set_sunset_date
    self.sunset_date = sunset_date_calc
  end

  def max_class_expiry_date
    attendances.no_amnesty.confirmed.includes(:wkclass).map(&:start_time).max
  end

  def check_if_already_had_trial
    already_had_trial = if persisted?
                          # editing from non-trial to trial. Note Self is the new intended purchase, not the same as the original Purchase.find(id) purchase
                          # if the original purchase is not a trial and product of the edited purchase is a trial and the client has had a trial...
                          !Purchase.find(id).trial? && product.trial? && client.has_had_trial?
                        else
                          product&.trial? && client&.has_had_trial?
                        end

    errors.add(:base, 'Client has already had a trial') if already_had_trial
  end

  def payment_amount_equals_charge
    # NOTE: 'retun if restart_as_child' would be semantcally clearer but the Restart only gets associated with the Purchase after the Purchase has been saved, so self.restart_as_child is nil at this point 
    return if payment.nil? # this is the case if a restart as the payment is associated with the Restart not the purchase

    mismatch = charge != payment.amount && payment.payment_mode != 'Not paid'

    errors.add(:base, 'The payment amount does not equal the charge, but the payment mode is not shown as Not paid') if mismatch
  end

  def attendance_status(attendance_count_provisional, attendance_count_confirmed, provisional: true)
    return 'not started' if attendance_count_provisional.zero?

    attendance_count = provisional ? attendance_count_provisional : attendance_count_confirmed
    return 'exhausted' if attendance_count >= max_classes
    return 'booked but not started' if attendance_count_confirmed.zero?
    # 'started'
    return 'unlimited' if max_classes == 1000

    attendance_count if attendance_count < max_classes
  end

  def validity(attendance_count, expiry_date)
    return if attendance_count.zero?
    return 'expired' if Time.zone.today > expiry_date

    expiry_date - start_date
  end

  def status_hash
    attendance_count_provisional = attendances.no_amnesty.size
    attendance_count_confirmed = attendances.no_amnesty.confirmed.size
    { attendance_provisional:
       attendance_status(attendance_count_provisional, attendance_count_confirmed, provisional: true),
      attendance_confirmed:
       attendance_status(attendance_count_provisional, attendance_count_confirmed, provisional: false),
      validity: validity(attendance_count_provisional, expiry_date_calc) }
  end

end
