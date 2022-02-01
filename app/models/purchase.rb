class Purchase < ApplicationRecord
  belongs_to :product
  belongs_to :client
  belongs_to :fitternity, optional: true
  has_many :attendances, dependent: :destroy
  has_many :adjustments, dependent: :destroy
  has_many :freezes, dependent: :destroy
  # this defines the name method on an instance of Purchase
  # so @purchase.name equals Product.find(@purchase.id).name
  delegate :name, to: :product
  delegate :revenue_for_class, to: :client
  validates :payment, presence: true
  validates :payment_mode, presence: true
  validates :invoice, allow_blank: true, length: { minimum: 5, maximum: 10 },
                    uniqueness: { case_sensitive: false }
  validates_associated :client, :product
  # validates :ar_payment, presence: true, if: :adjust_restart?
  with_options if: :adjust_restart? do |ar|
    ar.validates :ar_payment, presence: true
    ar.validates :ar_date, presence: true
  end
  validate :fitternity_payment
  scope :not_expired, -> { where('expired = ?', false) }
  # simple solution (more complex variants) courtesy of Yuri Karpovich https://stackoverflow.com/questions/20183710/find-all-records-which-have-a-count-of-an-association-greater-than-zero  
  scope :started, -> { joins(:attendances).distinct }
  # wg is an array of workout group names
  # see 3.3.3 subset conditions https://guides.rubyonrails.org/active_record_querying.html#pure-string-conditions
  scope :with_workout_group, ->(wg) { joins(product: [:workout_group]).where(workout_groups: {name: wg}) }
  scope :with_package, -> { joins(:product).where("products.max_classes > 1") }
  scope :order_by_client_dop, -> { joins(:client).order(:first_name, dop: :desc) }
  scope :order_by_dop, -> { order(dop: :desc) }
  scope :client_name_like, ->(name) { joins(:client).where("clients.first_name ILIKE ? OR clients.last_name ILIKE ?", "%#{name}%", "%#{name}%") }
  scope :uninvoiced, -> { where(invoice: nil)}
  scope :invoiced, -> { where.not(invoice: nil)}
  paginates_per 20

  def full_name
    "#{name} : #{number_to_currency(self.payment, precision: 0, unit: '')}"
  end

  def status
    return 'expired' if self.adjust_restart?
    status_hash = self.status_hash
    return 'not started' if status_hash[:attendance_status] == 'not started'
    return 'expired' if status_hash[:attendance_status] == 'exhausted' || status_hash[:validity_status] == 'expired'
    return 'frozen' if freezed?(Date.today)
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

  # def has_expiry_date?
  #   statuses = %w[ongoing frozen]
  #   statuses.include?(status)
  # end

  def expired_in?(month_year)
    expired? && expiry_date.strftime('%b %Y') == month_year
  end

  def expiry_cause
    return 'adjust & restart' if adjust_restart
    return 'used max classes' if attendances.size == product.max_classes
    return 'max time period'
  end

  def expired_on
    return ar_date.strftime('%d %b %y') if adjust_restart
    return max_class_expiry_date.strftime('%d %b %y') if attendances.size == product.max_classes
    return expiry_date.strftime('%d %b %y')
  end

  def expiry_date
    return ar_date if adjust_restart
    return dop if attendances.size.zero?
    start_date = self.start_date
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
      # end_date formulae above overstate by 1 day so deduct 1
      end_date + added_days + frozen_days - 1.day
  end

  def expiry_date_formatted
    # expiry_date.strftime("%d-%m-%Y")
    # expiry_date&.strftime('%a %d %b %y')
    expiry_date&.strftime('%d %b %y')
  end

  def days_to_expiry
    if ['ongoing', 'frozen'].include?(self.status)
      (expiry_date.to_date - Date.today).to_i
    else
      1000
    end
  end

  # def days_to_expiry
  #   return 1000 unless status == 'ongoing'
  #   (expiry_date.to_date - Date.today).to_i
  # end

  # def days_to_expiry_format
  #   return [days_to_expiry, ActionController::Base.helpers.image_tag('calendar.png', class: "infinity_icon")] if status == 'ongoing'
  #   ['','']
  # end

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
    attendance_revenue = attendances.map { |a| a.revenue }.inject(0, :+)
    # attendance revenue should never be more than payment, but if it somehow is, then it is consistent that expiry revenue should be negative
    return payment - attendance_revenue unless adjust_restart?
    ar_payment - attendance_revenue
  end

  def start_to_expiry
    status_hash = self.status_hash
    return status_hash[:attendance_status] if status_hash[:attendance_status] == 'not started'
    return "#{start_date.strftime('%d %b %y')} - #{expiry_date_formatted}"
  end

  def attendances_remain_format
    ac = attendances.count
    # "[number] [attendances icon] [more icon]"
    base_html = "#{ac} #{ActionController::Base.helpers.image_tag('attendances.png', class: 'header_icon')} #{ActionController::Base.helpers.image_tag('more.png', class: 'header_icon')}"
    pmc = product.max_classes
    # unlimited
    return "#{base_html} #{ActionController::Base.helpers.image_tag('infinity.png', class: 'infinity_icon')}".html_safe if pmc == 1000
    # unused classes
    return "#{base_html} #{pmc} (#{pmc - ac})".html_safe if ac < pmc
    # otherwise
    "#{base_html} #{pmc}".html_safe
  end

  def attendances_remain_numeric
    return product.max_classes - attendances.count if status == 'ongoing'
    return 1000
  end

  def attendances_remain(unlimited_text: true)
    ac = attendances.count
    pmc = product.max_classes
    return 'unlimited' if pmc == 1000 && unlimited_text == true
    pmc - ac
  end

  # apply to ongoing purchases. Not designed to work sensibly with an expired purchase
  def close_to_expiry?(days_remain: 5, attendances_remain: 2)
    return true if attendances_remain(unlimited_text: false) < attendances_remain || days_to_expiry < days_remain
    false
  end

  # def self.client_name_search(name)
  #    joins(:client)
  #   .where("clients.first_name ILIKE ? OR clients.last_name ILIKE ?", "%#{name}%", "%#{name}%")
  # end

  private
    def start_date
      # attendances.sort_by { |a| a.start_time }.first.start_time
      # use includes to avoid firing additional query per wkclass
      attendances.includes(:wkclass).map(&:start_time).min
    end

    def max_class_expiry_date
      attendances.includes(:wkclass).map(&:start_time).max
    end

    def attendance_status(attendance_count, max_classes)
      return 'not started' if attendance_count.zero?
      return 'unlimited' if max_classes == 1000
      return attendance_count if attendance_count < max_classes
      'exhausted'
    end

    def validity_status(attendance_count, expiry_date)
      return 'not started' if attendance_count.zero?
      return 'expired' if Date.today() > expiry_date
      expiry_date - start_date
    end

    def status_hash
      attendance_count = self.attendances.size
      { attendance_status: attendance_status(attendance_count, self.product.max_classes),
        validity_status: validity_status(attendance_count, self.expiry_date),
      }
    end

    def fitternity_payment
        if payment_mode == 'Fitternity'
          ong_fit_packages = Fitternity.select { |f| !(f.expired?) }
          errors.add(:base, "No ongoing Fitternity package") if ong_fit_packages.size.zero?
          return
        end
    end
end
