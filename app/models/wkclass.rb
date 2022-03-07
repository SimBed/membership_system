class Wkclass < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :confirmed_attendances, -> { where(status: Rails.application.config_for(:constants)["attendance_status_does_count"].reject { |a| a == 'booked'}) }, class_name: 'Attendance'
  has_many :provisional_attendances, -> { where(status: Rails.application.config_for(:constants)["attendance_status_does_count"]) }, class_name: 'Attendance'
  has_many :physical_attendances, -> { where(status: 'attended') }, class_name: 'Attendance'
  has_many :purchases, through: :attendances
  has_many :clients, through: :purchases
  belongs_to :instructor
  belongs_to :workout
  validate :instructor_rate_exists
  validate :unique_workout_time_combo
  delegate :name, to: :workout
  delegate :name, to: :instructor, prefix: true
  scope :order_by_date, -> { order(start_time: :desc) }
  scope :has_instructor_cost, -> { where.not(instructor_cost: nil) }
  scope :between, ->(start_date, end_date) { where({ start_time: (start_date..end_date) }).order(:start_time) }
  scope :todays_class, -> { where(start_time: Date.today.beginning_of_day..Date.today.end_of_day)}
  scope :yesterdays_class, -> { where(start_time: Date.yesterday.beginning_of_day..Date.yesterday.end_of_day)}
  scope :tomorrows_class, -> { where(start_time: Date.tomorrow.beginning_of_day..Date.tomorrow.end_of_day)}
  scope :past, -> { where('start_time < ?', Date.today.beginning_of_day) }
  scope :future, -> { where.not(id: past) }
  paginates_per 100
  # scope :next, ->(id) {where("wkclasses.id > ?", id).last || last}
  # scope :prev, ->(id) {where("wkclasses.id < ?", id).first || first}

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
    attendances.confirmed.map { |a| a.revenue }.inject(0, :+)
  end

# improve - add 'All' as an optional parameter..then refactor for_client_purchase in attendance.rb
  def self.in_workout_group(workout_group_name)
     joins(workout: [rel_workout_group_workouts: [:workout_group]])
    .where("workout_groups.name = ?", "#{workout_group_name}")
  end

  # def self.by_date(start_date, end_date)
  #   Wkclass.where("start_time BETWEEN '#{start_date}' AND '#{end_date}'")
  #          .order(:start_time)
  # end

  # def self.in_workout_group(workout_group_name).between(start_date, end_date)
  #   # method used in workout_group controller for @wkclasses_with_instructor_cost
  #   # which is then used to output wkclass name and instructor name (so workout and instructor are 'included' to avoid multiple fires to the database)
  #   Wkclass.includes(:instructor).includes(:workout)
  #     .joins(workout: [rel_workout_group_workouts: [:workout_group]])
  #     .where("wkclasses.start_time BETWEEN '#{start_date}' AND '#{end_date}'")
  #     .where("workout_groups.name = ?", "#{workout_group_name}")
  # end

  # def self.in_workout_group(workout_group_name).between(start_date, end_date)
  #   # method used in workout_group controller for @wkclasses_with_instructor_cost
  #   # which is then used to output wkclass name and instructor name (so workout and instructor are 'included' to avoid multiple fires to the database)
  #   Wkclass.includes(:instructor).includes(:workout)
  #     .between(start_date, end_date)
  #     .joins(workout: [rel_workout_group_workouts: [:workout_group]])
  #     .where("workout_groups.name = ?", "#{workout_group_name}")
  #     .order(:start_time)
  # end

  # for qualifying purchases in select box for new attendance form
  def self.clients_with_purchase_for(wkclass)
    # note: If the column in select is not one of the attributes of the model on which the select is called on then those columns are not displayed. All of these attributes are still contained in the objects within AR::Relation and are accessible as any other public instance attributes.
    client_purchase_ids =
    WorkoutGroup.joins(products: [purchases: [:client]]).merge(WorkoutGroup.includes_workout_of(wkclass)).merge(Purchase.not_expired)
    .order("clients.first_name", "purchases.dop")
    .select('clients.id as clientid, purchases.id as purchaseid')
    client_purchase_ids.to_a.select do |cp|
      purchase = Purchase.find(cp["purchaseid"])
      !purchase.expired? &&!purchase.provisionally_expired? && !purchase.freezed?(wkclass.start_time)
     end
  end

  # previous for clients_with_purchase_for with lots of nested joins and no scope on association
  # def self.clients_with_product(wkclass)
  #   client_purchase_ids =
  #    Wkclass.joins(workout: [rel_workout_group_workouts: [workout_group: [products: [purchases: [:client]]]]])
  #           .where("wkclasses.id = #{wkclass.id}")
  #           .order("clients.first_name")
  #           .select('clients.id as clientid, purchases.id as purchaseid')
  #   client_purchase_ids.to_a.select { |cp| !Purchase.find(cp["purchaseid"]).expired? && !Purchase.find(cp["purchaseid"]).freezed?(wkclass.start_time) }
  # end

# alternative code with direct SQL rather than Active record helper methods
  # def self.clients_with_product(wkclass)
  #   sql = "SELECT clients.id AS clientid, purchases.id AS purchaseid
  #          FROM Wkclasses
  #           INNER JOIN workouts ON wkclasses.workout_id = workouts.id
  #           INNER JOIN rel_workout_group_workouts rel ON workouts.id = rel.workout_id
  #           INNER JOIN workout_groups ON rel.workout_group_id = workout_groups.id
  #           INNER JOIN products on workout_groups.id = products.workout_group_id
  #           INNER JOIN purchases ON products.id = purchases.product_id
  #           INNER JOIN clients ON purchases.client_id = clients.id
  #           WHERE Wkclasses.id = #{wkclass.id} ORDER BY clients.first_name;"
  #           # [{"clientid"=>1, "purchaseid"=>1}, {"clientid"=>2, "purchaseid"=>2},...
  #   ActiveRecord::Base.connection.exec_query(sql).to_a.select { |cp| !Purchase.find(cp["purchaseid"]).expired? && !Purchase.find(cp["purchaseid"]).freezed?(wkclass.start_time) }
  # end
  private
    def instructor_rate_exists
      errors.add(:base, "Instructor does not have a rate") if Instructor.exists?(instructor_id) && instructor.current_rate.nil?
    end

    def unique_workout_time_combo
      wkclass = Wkclass.where(["workout_id = ? and start_time = ?", workout_id, start_time])
      wkclass.each do |w|
        if id != wkclass.first.id
          errors.add(:base, "A class for this workout and time already exists") if wkclass.present?
          return
        end
      end
    end
end
