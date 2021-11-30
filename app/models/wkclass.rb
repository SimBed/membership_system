class Wkclass < ApplicationRecord
  has_many :attendances
  has_many :rel_user_products, through: :attendances
  has_many :users, through: :rel_user_products
  belongs_to :workout

  def date
    start_time.strftime('%a %d %b %y')
  end

  def time
    start_time.strftime('%H:%M')
  end

  def summary
    "#{workout.name}, #{date}, #{time}"
  end

  def self.users_with_product(wkclass)
    sql = "SELECT users.id AS userid, relup.id AS relid
           FROM Wkclasses
            INNER JOIN workouts ON wkclasses.workout_id = workouts.id
            INNER JOIN Rel_product_workouts rel ON workouts.id = rel.workout_id
            INNER JOIN products on products.id = rel.product_id
            INNER JOIN rel_user_products relup ON relup.product_id = products.id
            INNER JOIN users ON users.id = relup.user_id
            WHERE Wkclasses.id = #{wkclass.id} ORDER BY userid;"
    ActiveRecord::Base.connection.exec_query(sql).to_a
  end
end
