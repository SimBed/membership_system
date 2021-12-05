class Purchase < ApplicationRecord
  belongs_to :product
  belongs_to :client
  has_many :attendances
  # this defines the name method on an instance of Purchase
  # so @purchase.name equals Product.find(@purchase.id).name
  delegate :name, to: :product
  delegate :revenue_for_class, to: :client

  def status
    return 'not started' if self.attendance_status == 'not started'
    return 'expired' if self.attendance_status == 'exhausted' || self.validity_status == 'expired'
    'ongoing'
  end

  def expiry_date
    start_date = self.attendances.order_by_date.first["date"]
    case product.validity_unit
      when 'D'
        return start_date + self.product.validity_length
      when 'W'
        return start_date + self.product.validity_length.weeks
      when 'M'
        return start_date + self.product.validity_length.months
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
          # assume 5 classes per week when unlimited and product in weeks
          return self.product.validity_length * 6 #5
        when 'M'
          return self.product.validity_length * 30 #20
      end
  end

  private
    def attendance_status
      attendance_count = self.attendances.count
      return 'not started' if attendance_count.zero?
      return attendance_count if attendance_count < self.product.max_classes
      'exhausted'
    end

    def validity_status
      return 'not started' if self.attendance_status == 'not started'
      return 'expired' if Date.today() > self.expiry_date
      start_date = self.attendances.order_by_date.first["date"]
      self.expiry_date - start_date
    end
end
