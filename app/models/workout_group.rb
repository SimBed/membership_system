class WorkoutGroup < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :purchases, through: :products
  has_many :attendances, through: :purchases
  has_many :expenses, dependent: :destroy
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workouts, through: :rel_workout_group_workouts
  attr_accessor :workout_ids

  validates :name, presence: true
  validates :workout_ids, presence: true
  after_create :create_rel_workout_group_workout
  after_update :update_rel_workout_group_workout
  scope :order_by_name, -> { order(:name) }

  def pt?
    return true if service == 'pt'

    false
  end

  def groupex?
    return true if service == 'group'

    false
  end

  def online?
    return true if service == 'online'

    false
  end

  def attendances_during(period)
    Attendance.includes(purchase: [:product]).confirmed.no_amnesty.by_workout_group(name, period)
  end

  def wkclasses_during(period)
    Wkclass.in_workout_group(name).during(period)
  end

  def base_revenue(period)
    attendances_during(period).map(&:revenue).inject(0, :+)
  end

  def gross_revenue(period)
    base_revenue(period) + expiry_revenue(period)
  end

  def gst(period)
    gross_revenue(period) * (1 - (1 / (1 + gst_rate)))
  end

  def net_revenue(period)
    gross_revenue(period) - gst(period)
  end

  def fixed_expense(period)
    Expense.by_workout_group(name, period).sum(:amount)
  end

  def variable_expense(period)
    Wkclass.in_workout_group(name)
           .during(period)
           .has_instructor_cost
           .sum(:instructor_cost)
  end

  def total_expense(period)
    fixed_expense(period) + variable_expense(period)
  end

  def profit(period)
    net_revenue(period) - total_expense(period)
  end

  def self.includes_workout_of(wkclass)
    joins(rel_workout_group_workouts: [:workout])
      .where(workouts: { name: wkclass.name.to_s })
    # .where("Workouts.name = ?", "#{wkclass.name}")
  end

  def workout_list
    workouts.pluck(:name).join(', ')
  end

  def gst_rate
    return 0 unless gst_applies

    # Setting.gst_rate.to_f / 100
    Rails.application.config_for(:constants)['gst_rate'].to_f / 100
  end

  def expiry_revenue(period)
    # purchases.fully_expired.select { |p| p.expired_in?(period) }.map(&:expiry_revenue).inject(0, :+)
    purchases.expired_in(period).map(&:expiry_revenue).inject(0, :+)
  end

  def create_rel_workout_group_workout
    workout_ids.each { |wid| RelWorkoutGroupWorkout.create(workout_group_id: id, workout_id: wid) }
  end

  def update_rel_workout_group_workout
    # toimprove
    # this prevents updates (with update method) through the console as workout_ids is nil...use update_column which won't trigger callbacks
    rel_workout_group_workouts.each(&:destroy)
    workout_ids.each { |wid| RelWorkoutGroupWorkout.create(workout_group_id: id, workout_id: wid) }
  end
end
