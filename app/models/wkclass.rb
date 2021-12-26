class Wkclass < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :purchases, through: :attendances
  has_many :clients, through: :purchases
  belongs_to :workout
  delegate :name, to: :workout
  scope :order_by_date, -> { order(start_time: :desc) }

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

  def self.by_date(start_date, end_date)
      Wkclass.where("start_time BETWEEN '#{start_date}' AND '#{end_date}'")
             .order(:start_time)
  end

  # for qualifying products in select box for new attendance form
  def self.clients_with_product(wkclass)
    sql = "SELECT clients.id AS clientid, purchases.id AS purchaseid
           FROM Wkclasses
            INNER JOIN workouts ON wkclasses.workout_id = workouts.id
            INNER JOIN rel_workout_group_workouts rel ON workouts.id = rel.workout_id
            INNER JOIN workout_groups ON rel.workout_group_id = workout_groups.id
            INNER JOIN products on workout_groups.id = products.workout_group_id
            INNER JOIN purchases ON products.id = purchases.product_id
            INNER JOIN clients ON purchases.client_id = clients.id
            WHERE Wkclasses.id = #{wkclass.id} ORDER BY clientid;"
            # [{"clientid"=>1, "purchaseid"=>1}, {"clientid"=>2, "purchaseid"=>2},...
    ActiveRecord::Base.connection.exec_query(sql).to_a.select { |cp| !Purchase.find(cp["purchaseid"]).expired? && !Purchase.find(cp["purchaseid"]).freezed?(wkclass.start_time) }
  end

end
