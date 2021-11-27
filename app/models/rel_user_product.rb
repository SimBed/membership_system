class RelUserProduct < ApplicationRecord
  belongs_to :product
  belongs_to :user
  has_many :attendances

  def status
    return 'not started' if self.attendance_status == 'not started'
    return 'expired' if self.attendance_status == 'exhausted' || self.validity_status == 'expired'
    return 'ongoing'
  end

  private
    def attendance_status
      attendance_count = self.attendances.count
      return 'not started' if attendance_count.zero?
      return attendance_count if attendance_count < self.product.max_classes
      return 'exhausted'
    end

    def validity_status
      return 'not started' if self.attendance_status == 'not started'
      start_date = self.attendances.order_by_date.first["date"]
      expiry_date = start_date + self.product.validity_length
      return 'expired' if expiry_date > Date.today()
      return expiry_date - start_date
    end

end
