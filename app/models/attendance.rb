class Attendance < ApplicationRecord
  belongs_to :wkclass
  belongs_to :rel_user_product

  def self.order_by_date
    sql = "SELECT wkclasses.start_time date
           FROM attendances
           INNER JOIN wkclasses ON wkclasses.id = attendances.wkclass_id
           ORDER BY date ASC;"
      ActiveRecord::Base.connection.exec_query(sql).to_a
  end
end
