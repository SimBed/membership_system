require 'byebug'
class Purchase < ApplicationRecord
  belongs_to :product
  belongs_to :client
  has_many :attendances
  has_many :adjustments, dependent: :destroy
  has_many :freezes, dependent: :destroy
  scope :not_expired, -> { where('expired = ?', false) }
  # this defines the name method on an instance of Purchase
  # so @purchase.name equals Product.find(@purchase.id).name
  delegate :name, to: :product
  delegate :revenue_for_class, to: :client

  def status
    return 'expired' if self.adjust_restart?
    return 'not started' if self.attendance_status == 'not started'
    return 'expired' if self.attendance_status == 'exhausted' || self.validity_status == 'expired'
    'ongoing'
  end

  def expired?
    status == 'expired'
  end

  def expired_in?(month_year)
    expired? && expiry_date.strftime('%b %Y') == month_year
  end

  def expiry_date
    #byebug
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
    expiry_date.strftime("%d-%m-%Y")
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
          return self.product.validity_length * 30 #20
      end
  end

  def expiry_revenue
    attendance_revenue = attendances.map { |a| a.revenue }.inject(:+)
    # attendance revenue should never be more than payment, but if it somehow is, then it is consistent that expiry revenue should be negative
    return payment - attendance_revenue unless adjust_restart?
    ar_payment - attendance_revenue
  end

  private
    def start_date
      attendances.sort_by { |a| a.start_time }.first.start_time
    end

    def attendance_status
      attendance_count = self.attendances.count
      return 'not started' if attendance_count.zero?
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
