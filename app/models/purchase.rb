class Purchase < ApplicationRecord
  belongs_to :product
  belongs_to :client
  belongs_to :fitternity, optional: true
  belongs_to :price
  has_many :attendances, dependent: :destroy
  has_many :adjustments, dependent: :destroy
  has_many :freezes, dependent: :destroy
  has_many :penalties, dependent: :destroy
  # this defines the name method on an instance of a Purchase
  # so @purchase.name equals Product.find(@purchase.id).name
  delegate :name, :workout_group, :dropin?, :trial?, :unlimited_package?, :fixed_package?, :product_type, :max_classes,
           :attendance_estimate, to: :product
  validates :payment, presence: true
  validates :payment_mode, presence: true
  validates :invoice, allow_blank: true, length: { minimum: 5, maximum: 10 }
  # validates :ar_payment, presence: true, if: :adjust_restart?
  with_options if: :adjust_restart? do
    validates :ar_payment, presence: true
    validates :ar_date, presence: true
  end
  validate :fitternity_payment
  validates :fitternity, presence: true, if: :fitternity_id
  scope :not_expired, lambda {
                        where.not(status: ['expired', 'provisionally expired'])
                      }
  scope :not_fully_expired, -> { where.not(status: 'expired') }
  # simple solution using distinct (more complex variants) courtesy of Yuri Karpovich https://stackoverflow.com/questions/20183710/find-all-records-which-have-a-count-of-an-association-greater-than-zero
  # scope :started, -> { joins(:attendances).merge(Attendance.no_amnesty).distinct }
  scope :started, -> { where.not(status: 'not started') }
  # wg is an array of workout group names
  # see 3.3.3 subset conditions https://guides.rubyonrails.org/active_record_querying.html#pure-string-conditions
  scope :with_workout_group, ->(wg) { joins(product: [:workout_group]).where(workout_groups: { name: wg }) }
  # stata is an array of purchases statuses
  scope :with_statuses, ->(stata) { where(status: stata) }
  # 'using a scope through an association'
  # https://apidock.com/rails/ActiveRecord/SpawnMethods/merge
  scope :with_package, -> { joins(:product).merge(Product.package) }
  # alternative 'mixes concerns and logic'
  # scope :with_package, -> { joins(:product).where("max_classes > 1") }
  scope :order_by_client_dop, -> { joins(:client).order(:first_name, dop: :desc) }
  scope :order_by_dop, -> { order(dop: :desc) }
  scope :order_by_expiry_date, -> { order(:expiry_date) }
  scope :client_name_like, ->(name) { joins(:client).merge(Client.name_like(name)) }
  # scope :client_name_like, ->(name) { joins(:client).where("first_name ILIKE ? OR last_name ILIKE ?", "%#{name}%", "%#{name}%") }
  scope :uninvoiced, -> { where(invoice: nil) }
  scope :requires_invoice, -> { joins(product: [:workout_group]).where(workout_groups: { requires_invoice: true }) }
  scope :invoiced, -> { where.not(invoice: nil) }
  scope :unpaid, -> { where(payment_mode: 'Not paid') }
  scope :classpass, -> { where(payment_mode: 'ClassPass') }
  # scope :not_used_on?, ->(adate) { joins(attendances: [:wkclass]).merge(Wkclass.not_between(adate, adate.end_of_day)).distinct}
  # scope :not_used_on?, ->(adate) { left_outer_joins(attendances: [:wkclass]).where.not(wkclasses: {start_time: adate..adate.end_of_day}).distinct }
  # note the 'unscope' see genkilabs solution @ https://stackoverflow.com/questions/42846286/pginvalidcolumnreference-error-for-select-distinct-order-by-expressions-mus
  # scope :used_on?, ->(adate) { joins(attendances: [:wkclass]).merge(Wkclass.between(adate, adate.end_of_day)).unscope(:order).distinct}
  paginates_per 20

  def self.available_to(wkclass)
    not_expired
      .joins(product: [:workout_group])
      .joins(:client)
      .merge(WorkoutGroup.includes_workout_of(wkclass))
      .includes(:client)
      .order('clients.first_name', 'purchases.dop')
  end

  def self.qualifying_for(wkclass)
    available_to(wkclass).reject do |p|
      p.freezed?(wkclass.start_time) ||
        p.committed_on?(wkclass.start_time.to_date)
    end
  end

  def self.available_for_booking(wkclass, client)
    available_to(wkclass).where(client_id: client.id).reject do |p|
      p.freezed?(wkclass.start_time) ||
        p.committed_on?(wkclass.start_time.to_date)
    end
  end

  def self.earliest_available_for_booking(wkclass, client)
    # in unusual case of more than one available purchase, use the started one (earliest dop if still a choice) or the earliest dop if no started one
    purchases = available_for_booking(wkclass, client)
    started_purchases = purchases.reject(&:not_started?)
    started_purchases.nil? ? started_purchases[0] : purchases[0]
  end

  def self.by_product_date(product_id, start_date, end_date)
    joins(:product)
      .where("purchases.dop BETWEEN '#{start_date}' AND '#{end_date}'")
      .where(products: { id: product_id.to_s })
      .order(dop: :desc)
  end

  def revenue_for_class(wkclass)
    return 0 unless wkclass.purchases.include?(self)

    payment / product.attendance_estimate
  end

  def committed_on?(adate)
    attendances.cant_rebook.includes(:wkclass).map { |a| a.start_time.to_date }.include?(adate)
  end

  def name_with_dop
    "#{name} - #{dop.strftime('%d %b %y')}"
  end

  def status_calc
    return 'expired' if adjust_restart?

    status_hash = self.status_hash
    return 'not started' if status_hash[:attendance_provisional] == 'not started'
    return 'booked but not started' if status_hash[:attendance_provisional] == 'booked but not started'
    return 'expired' if status_hash[:attendance_confirmed] == 'exhausted' || status_hash[:validity] == 'expired'
    return 'provisionally expired' if status_hash[:attendance_provisional] == 'exhausted'

    # return 'booked first class'

    'ongoing'
  end

  def freezed?(adate)
    freezes.each do |f|
      return true if adate.between?(f.start_date, f.end_date)
    end
    false
  end

  def expired?
    status == 'expired'
  end

  def not_started?
    status == 'not started'
  end

  def provisionally_expired?
    ['provisionally expired'].include?(status)
  end

  def expired_in?(month_year)
    expired? && expiry_date.strftime('%b %Y') == month_year
  end

  def expiry_cause
    return unless expired?
    return 'adjust & restart' if adjust_restart
    return 'used max classes' if attendances.no_amnesty.confirmed.size == max_classes

    'max time period'
  end

  def expired_on
    return unless expired?
    return ar_date.strftime('%d %b %y') if adjust_restart
    return max_class_expiry_date.strftime('%d %b %y') if attendances.no_amnesty.confirmed.size == max_classes

    expiry_date.strftime('%d %b %y')
  end

  def will_expire_on
    return nil unless provisionally_expired?

    attendances.no_amnesty.includes(:wkclass).map(&:start_time).max.strftime('%d %b %y')
  end

  def expiry_date_calc
    return ar_date if adjust_restart?
    return if attendances.no_amnesty.size.zero?

    # end_date formulae above overstate by 1 day so deduct 1
    # to_date changes ActiveSupport::TimeWithZone object to Date object
    # as 'Sun, 12 Dec 2021' preferred to 'Sun, 12 Dec 2021 10:30:00.000000000 UTC +00:00'
    (start_date + product.duration_days + extra_days - 1.day).to_date
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

    attendance_revenue = attendances.no_amnesty.confirmed.map(&:revenue).inject(0, :+)
    # attendance revenue should never be more than payment, but if it somehow is, then it is consistent that expiry revenue should be negative
    return payment - attendance_revenue unless adjust_restart?

    ar_payment - attendance_revenue
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

  def start_date_calc
    attendances.no_amnesty.includes(:wkclass).map(&:start_time).min&.to_date
  end

  private

  def max_class_expiry_date
    attendances.no_amnesty.confirmed.includes(:wkclass).map(&:start_time).max
  end

  def attendance_status(attendance_count_provisional, attendance_count_confirmed, provisional: true)
    return 'not started' if attendance_count_provisional.zero?
    return 'booked but not started' if attendance_count_confirmed.zero?
    return 'unlimited' if max_classes == 1000

    attendance_count = provisional ? attendance_count_provisional : attendance_count_confirmed
    return attendance_count if attendance_count < max_classes

    'exhausted'
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

  def fitternity_payment
    return unless payment_mode == 'Fitternity'

    errors.add(:base, 'No ongoing Fitternity package') if Fitternity.ongoing.size.zero?
  end
end
