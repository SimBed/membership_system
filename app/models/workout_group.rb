class WorkoutGroup < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :purchases, through: :products
  has_many :attendances, through: :purchases
  # has_many :wkclasses, through: :attendances
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workouts, through: :rel_workout_group_workouts

  attr_accessor :workout_ids
  after_create :create_rel_workout_group_workout
  after_update :update_rel_workout_group_workout

  def attendances_in(revenue_date)
    attendances.in_month(Date.parse(revenue_date), Date.parse(revenue_date) + 1.month).count
  end

  # def base_revenue(revenue_date)
  #   attendances.in_month(Date.parse(revenue_date), Date.parse(revenue_date) + 1.month).flatten.map { |a| a.revenue }.inject(0, :+)
  # end

  def expiry_revenue(revenue_date)
    purchases.select { |p| p.expired_in?(revenue_date) }.map { |p| p.expiry_revenue }.inject(0, :+)
  end

  # def total_revenue(revenue_date)
  #   base_revenue(revenue_date) + expiry_revenue(revenue_date)
  # end

  def create_rel_workout_group_workout
    workout_ids.each { |wid| RelWorkoutGroupWorkout.create(workout_group_id: id, workout_id: wid) }
  end

  def update_rel_workout_group_workout
    # toimprove
    rel_workout_group_workouts.each { |rel| rel.destroy }
    workout_ids.each { |wid| RelWorkoutGroupWorkout.create(workout_group_id: id, workout_id: wid) }
  end
end
