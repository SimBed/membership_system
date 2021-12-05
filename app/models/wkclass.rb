class Wkclass < ApplicationRecord
  has_many :attendances
  has_many :rel_user_products, through: :attendances
  has_many :users, through: :rel_user_products
  belongs_to :workout
  delegate :name, to: :workout

  def date
    start_time.strftime('%a %d %b %y')
  end

  def time
    start_time.strftime('%H:%M')
  end

  def summary
    "#{workout.name}, #{date}, #{time}"
  end

  def revenue
    attendances.map { |a| a.revenue }.inject(0, :+)
  end

  # for qualifying products in select box for new attendance form
  def self.users_with_product(wkclass)
    sql = "SELECT users.id AS userid, relup.id AS relid
           FROM Wkclasses
            INNER JOIN workouts ON wkclasses.workout_id = workouts.id
            INNER JOIN rel_workout_group_workouts rel ON workouts.id = rel.workout_id
            INNER JOIN workout_groups ON rel.workout_group_id = workout_groups.id
            INNER JOIN products on workout_groups.id = products.workout_group_id
            INNER JOIN rel_user_products relup ON products.id = relup.product_id
            INNER JOIN users ON relup.user_id = users.id
            WHERE Wkclasses.id = #{wkclass.id} ORDER BY userid;"
    ActiveRecord::Base.connection.exec_query(sql).to_a
  end
end
