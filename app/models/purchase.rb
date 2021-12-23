class Purchase < ApplicationRecord
  belongs_to :product
  belongs_to :client
  has_many :attendances, dependent: :destroy
  has_many :adjustments, dependent: :destroy
  has_many :freezes, dependent: :destroy
  scope :not_expired, -> { where('expired = ?', false) }
  # this defines the name method on an instance of Purchase
  # so @purchase.name equals Product.find(@purchase.id).name
  delegate :name, to: :product
  delegate :revenue_for_class, to: :client
  validates :payment, presence: true
  validates_associated :client, :product
  #validates :ar_payment, presence: true, if: :adjust_restart?
  with_options if: :adjust_restart? do |ar|
    ar.validates :ar_payment, presence: true
    ar.validates :ar_date, presence: true
  end
  # wg is an array of workout groups
  scope :with_workout_group, ->(wg) { joins(product: [:workout_group]).where(workout_groups: {name: wg}) }
  scope :order_by_client_dop, -> { joins(:client).order(:first_name, dop: :desc) }
  scope :order_by_dop, -> { order(dop: :desc) }

  # def self.by_client_dop
  #   Purchase.joins(:client)
  #           .order(:first_name, dop: :desc)
  # end

  def full_name
    "#{name} : #{number_to_currency(self.payment, precision: 0, unit: '')}"
  end

  def status
    return 'expired' if self.adjust_restart?
    return 'not started' if self.attendance_status == 'not started'
    return 'expired' if self.attendance_status == 'exhausted' || self.validity_status == 'expired'
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

  def expired_in?(month_year)
    expired? && expiry_date.strftime('%b %Y') == month_year
  end

  def expiry_date
    return ar_date if adjust_restart
    return self.dop if attendances.count.zero?
    start_date = self.start_date
    end_date = case product.validity_unit
      when 'D'
        start_date + self.product.validity_length
      when 'W'
        start_date + self.product.validity_length.weeks
      when 'M'
        start_date + self.product.validity_length.months
    end
      end_date + adjustments.map { |a| a.adjustment }.inject(0, :+).days
  end

  def expiry_date_formatted
    # expiry_date.strftime("%d-%m-%Y")
    expiry_date&.strftime('%a %d %b %y')
  end

  def days_to_expiry
    return 1000 unless status == 'ongoing'
    (expiry_date.to_date - Date.today).to_i
  end

  def days_to_expiry_format
    return [days_to_expiry, ActionController::Base.helpers.image_tag('calendar.png', class: "infinity_icon")] if status == 'ongoing'
    ['','']
  end

  # for revenue cashflows
  def attendance_estimate
    return product.max_classes unless product.max_classes == 1000
      case product.validity_unit
        when 'D'
          # probably no unlimited products with days but assume every day if so
          return self.product.validity_length
        when 'W'
          # assume 5 classes per week when unlimited and product in weeks
          return self.product.validity_length * 6 #5
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
    return attendance_status if attendance_status == 'not started'
    return "#{start_date.strftime('%d %b %y')} - #{expiry_date_formatted}"
  end

  def attendances_remain_format
    return ActionController::Base.helpers.image_tag('infinity.png', class: 'infinity_icon') unless attendance_status.is_a? Integer
    "#{product.max_classes} (#{product.max_classes - attendance_status})"
  end

  def attendances_remain_numeric
    return product.max_classes - attendances.count if status == 'ongoing'
    return 1000
  end



  private
    def start_date
      attendances.sort_by { |a| a.start_time }.first.start_time
    end

    def attendance_status
      attendance_count = self.attendances.count
      return 'not started' if attendance_count.zero?
      return 'unlimited' if product.max_classes == 1000
      return attendance_count if attendance_count < self.product.max_classes
      'exhausted'
    end

    def validity_status
      return 'not started' if self.attendance_status == 'not started'
      return 'expired' if Date.today() > self.expiry_date
      #byebug
      self.expiry_date - start_date
    end
end
