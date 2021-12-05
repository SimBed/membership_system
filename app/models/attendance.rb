class Attendance < ApplicationRecord
  belongs_to :wkclass
  belongs_to :purchase
  # this defines the start_time method on an instance of Wkclass
  # so @attendance.start_time equals WkClass.find(@attendance.id).start_time
  delegate :start_time, :date, to: :wkclass

  def revenue
    purchase.payment / purchase.attendance_estimate
  end

  # for expiry_date method of Purchase model
  def self.order_by_date
    sql = "SELECT wkclasses.start_time date
           FROM attendances
           INNER JOIN wkclasses ON wkclasses.id = attendances.wkclass_id
           ORDER BY date ASC;"
      ActiveRecord::Base.connection.exec_query(sql).to_a
  end
end
