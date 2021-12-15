class Attendance < ApplicationRecord
  belongs_to :wkclass
  belongs_to :purchase
  # this defines the start_time method on an instance of Wkclass
  # so @attendance.start_time equals WkClass.find(@attendance.id).start_time
  # date is a Wkclass instance method that formats start_time
  delegate :start_time, :date, to: :wkclass

  def revenue
    purchase.payment / purchase.attendance_estimate
  end

  def workout_group
    purchase.product.workout_group
  end

  # # for expiry_date method of Purchase model
  # def self.order_by_date
  #   sql = "SELECT wkclasses.start_time date
  #          FROM attendances
  #          INNER JOIN wkclasses ON wkclasses.id = attendances.wkclass_id
  #          ORDER BY date ASC;"
  #     ActiveRecord::Base.connection.exec_query(sql).to_a
  # end

  def self.by_workout_group(workout_group, start_date, end_date)
    sql = "SELECT attendances.id
           FROM Workout_Groups
           INNER JOIN Products ON Workout_Groups.id = Products.workout_group_id
           INNER JOIN Purchases ON Products.id = Purchases.product_id
           INNER JOIN Attendances ON Purchases.id = Attendances.purchase_id
           INNER JOIN Wkclasses ON Attendances.wkclass_id = Wkclasses.id
           WHERE Wkclasses.start_time BETWEEN '#{start_date}' AND '#{end_date}'
           AND Workout_Groups.name = '#{workout_group}';"
      # convert the query result to an array of hashes [ {id: 1}, {id: 3},...] and then to an array of ids
      attendance_ids = ActiveRecord::Base.connection.exec_query(sql).to_a.map(&:values)
      # return an array of objects, by using the find method with an array parameter
      Attendance.find(attendance_ids)
  end

  def self.by_client(clientid, start_date, end_date)
    sql = "SELECT attendances.id
           FROM Clients
           INNER JOIN Purchases ON Clients.id = Purchases.client_id
           INNER JOIN Attendances ON Purchases.id = Attendances.purchase_id
           INNER JOIN Wkclasses ON Attendances.wkclass_id = Wkclasses.id
           WHERE Wkclasses.start_time BETWEEN '#{start_date}' AND '#{end_date}'
           AND Clients.id = '#{clientid}'
           ORDER BY WkClasses.start_time desc;"
      # convert the query result to an array of hashes [ {id: 1}, {id: 3},...] and then to an array of ids
      attendance_ids = ActiveRecord::Base.connection.exec_query(sql).to_a.map(&:values)
      # return an array of objects, by using the find method with an array parameter
      Attendance.find(attendance_ids)
  end

  # not correct
  # def self.in_month(start_date, end_date)
  #   Wkclass.joins(:attendances).where("Wkclasses.start_time > ? AND Wkclasses.start_time < ?", start_date, end_date).map {|w| w.attendances}
  # end
end
