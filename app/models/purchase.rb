class Purchase < ApplicationRecord
  belongs_to :product
  belongs_to :client
  belongs_to :fitternity, optional: true
  belongs_to :price
  has_many :attendances, dependent: :destroy
  has_many :adjustments, dependent: :destroy
  has_many :freezes, dependent: :destroy
  has_many :penalties, dependent: :destroy
  # this defines the name method on an instance of Purchase
  # so @purchase.name equals Product.find(@purchase.id).name
  delegate :name, to: :product
  # delegate :revenue_for_class, to: :client
  delegate :workout_group, to: :product
  delegate :dropin?, to: :product
  delegate :max_classes, to: :product
  validates :payment, presence: true
  validates :payment_mode, presence: true
  validates :invoice, allow_blank: true, length: { minimum: 5, maximum: 10 },
                    uniqueness: { case_sensitive: false }
  # validates :ar_payment, presence: true, if: :adjust_restart?
  with_options if: :adjust_restart? do |ar|
    ar.validates :ar_payment, presence: true
    ar.validates :ar_date, presence: true
  end
  validate :fitternity_payment
  validates :fitternity, presence: true, if: :fitternity_id
  # scope :not_expired, -> { where('expired = ?', false) }
  scope :not_expired, -> { where.not(status: ['expired', 'provisionally expired', 'provisionally expired (and frozen)']) }
  # simple solution using distinct (more complex variants) courtesy of Yuri Karpovich https://stackoverflow.com/questions/20183710/find-all-records-which-have-a-count-of-an-association-greater-than-zero
  # scope :started, -> { joins(:attendances).merge(Attendance.provisional).distinct }
  scope :started, -> { where.not(status: 'not started') }
  # wg is an array of workout group names
  # see 3.3.3 subset conditions https://guides.rubyonrails.org/active_record_querying.html#pure-string-conditions
  scope :with_workout_group, ->(wg) { joins(product: [:workout_group]).where(workout_groups: {name: wg}) }
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
  scope :uninvoiced, -> { where(invoice: nil)}
  scope :requires_invoice, -> { joins(product: [:workout_group]).where(workout_groups: {requires_invoice: true}) }
  scope :invoiced, -> { where.not(invoice: nil)}
  scope :unpaid, -> { where(payment_mode: 'Not paid')}
  scope :classpass, -> { where(payment_mode: 'ClassPass')}
  #scope :not_used_on?, ->(adate) { joins(attendances: [:wkclass]).merge(Wkclass.not_between(adate, adate.end_of_day)).distinct}
  # scope :not_used_on?, ->(adate) { left_outer_joins(attendances: [:wkclass]).where.not(wkclasses: {start_time: adate..adate.end_of_day}).distinct }
  # note the 'unscope' see genkilabs solution @ https://stackoverflow.com/questions/42846286/pginvalidcolumnreference-error-for-select-distinct-order-by-expressions-mus
  # scope :used_on?, ->(adate) { joins(attendances: [:wkclass]).merge(Wkclass.between(adate, adate.end_of_day)).unscope(:order).distinct}
  paginates_per 20

  def revenue_for_class(wkclass)
    return 0 unless wkclass.purchases.include?(self)
    payment / attendance_estimate
  end

  def committed_on?(adate)
    attendances.cant_rebook.includes(:wkclass).map { |a| a.start_time.to_date}.include?(adate)
  end

  # for qualifying purchases in select box for new attendance form
  # this seems convoluted:
  # 1.convert the join to an array of purchases
  # 2.apply the purchase instance methods (that can't currently be done at database level)
  # 3.convert back to ActiveRecord_Relation to 'include' the clients so @qualifying purchases can be built
  # note 'where' doesn't preserve the order of the ids, hence the ordering after the 'includes' not as part of the original joins query
  def self.qualifying_for(wkclass)
    purchases = Purchase.not_expired
                        .joins(product: [:workout_group])
                        .joins(:client)
                        .merge(WorkoutGroup.includes_workout_of(wkclass))
    Purchase.where(id: purchases
                        .to_a.select { |p| !p.freezed?(wkclass.start_time) && !p.committed_on?(wkclass.start_time.to_date) }
                        .map(&:id) # or pluck(:id)
                  )
            .includes(:client).order("clients.first_name", "purchases.dop")
  end

  def self.available_for_booking(wkclass, client)
    purchases = Purchase.not_expired
                        .joins(product: [:workout_group])
                        .joins(:client)
                        .merge(WorkoutGroup.includes_workout_of(wkclass))
                        .where(client_id: client.id)
    purchases = Purchase.where(id: purchases
                        .to_a.select { |p| !p.freezed?(wkclass.start_time) && !p.committed_on?(wkclass.start_time.to_date) }
                        .map(&:id) # or pluck(:id)
                  )
                        .order("purchases.dop")
    # in unusual case of more than one available purchase, use the started one (earliest dop if still a choice) or the earliest dop if no started one
    started_purchases = purchases.select { |p| !p.not_started? }
    if started_purchases.nil?
      started_purchases[0]
    else
      purchases[0]
    end

  end

  def self.by_product_date(product_id, start_date, end_date)
      joins(:product)
     .where("purchases.dop BETWEEN '#{start_date}' AND '#{end_date}'")
     .where("products.id = ?", "#{product_id}")
     .order(dop: :desc)
  end

  def name_with_dop
    "#{name} - #{dop.strftime('%d %b %y')}"
  end

  def status_calc
    return 'expired' if self.adjust_restart?
    status_hash = self.status_hash
    return 'not started' if status_hash[:attendance_provisional_status] == 'not started'
    return 'expired' if status_hash[:attendance_confirmed_status] == 'exhausted' || status_hash[:validity_status] == 'expired'
    freezed = freezed?(Date.today)
    return 'provisionally expired (and frozen)' if status_hash[:attendance_provisional_status] == 'exhausted' && status_hash[:validity_status] != 'expired' && freezed
    return 'frozen' if freezed
    return 'provisionally expired' if status_hash[:attendance_provisional_status] == 'exhausted' && status_hash[:validity_status] != 'expired'
    return 'booked first class' if status_hash[:attendance_confirmed_status] == 'not started' && status_hash[:attendance_provisional_status] != 'not started'
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
    ['provisionally expired', 'provisionally expired (and frozen)'].include?(status)
  end

  def expired_in?(month_year)
    expired? && expiry_date.strftime('%b %Y') == month_year
  end

  def expiry_cause
    return unless expired?
    return 'adjust & restart' if adjust_restart
    return 'used max classes' if attendances.confirmed.size == product.max_classes
    return 'max time period'
  end

  def expired_on
    return unless expired?
    return ar_date.strftime('%d %b %y') if adjust_restart
    return max_class_expiry_date.strftime('%d %b %y') if attendances.confirmed.size == product.max_classes
    return expiry_date.strftime('%d %b %y')
  end

  def will_expire_on
    return nil unless provisionally_expired?
    attendances.provisional.includes(:wkclass).map(&:start_time).max.strftime('%d %b %y')
  end

  def expiry_date_calc
    return ar_date if adjust_restart
    return 'n/a' if attendances.provisional.size.zero?
    # expiry date is undefined for dropins. Avoid unexpected issues by setting to a day in the future
    return Date.tomorrow if product.dropin?
    start_date = self.start_date_calc
    end_date = case product.validity_unit
      when 'D'
        start_date + product.validity_length.days
      when 'W'
        start_date + product.validity_length.weeks
      when 'M'
        start_date + product.validity_length.months
    end

      added_days = adjustments.map { |a| a.adjustment }.inject(0, :+).days
      frozen_days = freezes.map { |f| f.duration}.inject(0, :+).days
      penalty_days = penalties.map { |p| p.amount}.inject(0, :+).days
      # end_date formulae above overstate by 1 day so deduct 1
      # to_date changes ActiveSupport::TimeWithZone object to Date object
      # as 'Sun, 12 Dec 2021' preferred to 'Sun, 12 Dec 2021 10:30:00.000000000 UTC +00:00'
      (end_date + added_days + frozen_days - penalty_days - 1.day).to_date
  end

  def days_to_expiry
    if ['ongoing', 'frozen', 'booked first class'].include?(self.status)
      (expiry_date - Date.today).to_i
    else
      # random high number is useful for sorting by days to expiry
      1000
    end
  end

  # for revenue cashflows
  def attendance_estimate
    return product.max_classes unless product.max_classes == 1000
      case product.validity_unit
        when 'D'
          # probably no unlimited products with days but assume every day if so
          return self.product.validity_length
        when 'W'
          # assume 6 classes per week when unlimited and product in weeks
          return self.product.validity_length * 6
        when 'M'
          return self.product.validity_length * 20 unless self.product.validity_length == 1
          25 # for 1M
      end
  end

  def expiry_revenue
    return 0 unless expired?
    attendance_revenue = attendances.confirmed.map { |a| a.revenue }.inject(0, :+)
    # attendance revenue should never be more than payment, but if it somehow is, then it is consistent that expiry revenue should be negative
    return payment - attendance_revenue unless adjust_restart?
    ar_payment - attendance_revenue
  end

  def start_to_expiry
    status_hash = self.status_hash
    return 'not started' if status_hash[:attendance_provisional_status] == 'not started'
    return "#{start_date.strftime('%d %b %y')} - #{expiry_date.strftime('%d %b %y')}"
  end

  def attendances_remain(provisional: true, unlimited_text: true)
    attendance_count = provisional ? attendances.provisional.size : attendances.confirmed.size
    return 'unlimited' if max_classes == 1000 && unlimited_text == true
    max_classes - attendance_count
  end

  # apply to ongoing packages. Not designed to work sensibly with an expired purchase
  def close_to_expiry?(days_remain: 5, attendances_remain: 2)
    #return false unless ongoing || booked first class || package
    return true if attendances_remain(unlimited_text: false) < attendances_remain || days_to_expiry < days_remain
    false
  end

  def start_date_calc
    # attendances.sort_by { |a| a.start_time }.first.start_time
    # use includes to avoid firing additional query per wkclass
    attendances.provisional.includes(:wkclass).map(&:start_time).min&.to_date
  end

  # def attendances_remain_format
  #   ac = attendances.count
  #   # "[number] [attendances icon] [more icon]"
  #   base_html = "#{ac} #{ActionController::Base.helpers.image_tag('attendances.png', class: 'header_icon')} #{ActionController::Base.helpers.image_tag('more.png', class: 'header_icon')}"
  #   pmc = product.max_classes
  #   # unlimited
  #   return "#{base_html} #{ActionController::Base.helpers.image_tag('infinity.png', class: 'infinity_icon')}".html_safe if pmc == 1000
  #   # unused classes
  #   return "#{base_html} #{pmc} (#{pmc - ac})".html_safe if ac < pmc
  #   # otherwise
  #   "#{base_html} #{pmc}".html_safe
  # end

  # def days_to_expiry
  #   return 1000 unless status == 'ongoing'
  #   (expiry_date.to_date - Date.today).to_i
  # end

  # def days_to_expiry_format
  #   return [days_to_expiry, ActionController::Base.helpers.image_tag('calendar.png', class: "infinity_icon")] if status == 'ongoing'
  #   ['','']
  # end

  # def expiry_date_formatted
  #   # expiry_date&.strftime('%d %b %y')
  #   @expiry_date = expiry_date
  #   return @expiry_date unless @expiry_date.is_a?(Time)
  #   @expiry_date.strftime('%d %b %y')
  # end

  # # violates MVC
  # # https://stackoverflow.com/questions/5176718/how-to-use-the-number-to-currency-helper-method-in-the-model-rather-than-view
  # def full_name
  #   "#{name_with_dop} - #{helpers.number_to_currency(self.payment, precision: 0, unit: 'Rs.')}"
  # end
  #
  # # http://railscasts.com/episodes/132-helpers-outside-views?autoplay=true  3m.45s
  # def helpers
  #   ActionController::Base.helpers
  # end

  # def name_with_price_name
  #   "#{name} - #{self.price.name}"
  # end

  private
    def max_class_expiry_date
      attendances.confirmed.includes(:wkclass).map(&:start_time).max
    end

    def attendance_status(attendance_count, max_classes)
      return 'not started' if attendance_count.zero?
      return 'unlimited' if max_classes == 1000
      #should this be max_classes - attendance_count
      return attendance_count if attendance_count < max_classes
      'exhausted'
    end

    def validity_status(attendance_count, expiry_date)
      return 'not started' if attendance_count.zero?
      return 'expired' if Date.today() > expiry_date
      expiry_date - start_date_calc
    end

    def status_hash
      attendance_provisional_count = self.attendances.provisional.size
      attendance_confirmed_count = self.attendances.confirmed.size
      { attendance_provisional_status: attendance_status(attendance_provisional_count, self.product.max_classes),
        attendance_confirmed_status: attendance_status(attendance_confirmed_count, self.product.max_classes),
        validity_status: validity_status(attendance_provisional_count, self.expiry_date_calc),
      }
    end

    def fitternity_payment
        if payment_mode == 'Fitternity'
          # ong_fit_packages = Fitternity.select { |f| !(f.expired?) }
          errors.add(:base, "No ongoing Fitternity package") if Fitternity.ongoing.size.zero?
          return
        end
    end
end
