class WorkoutGroup < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :rel_user_products, through: :products
  has_many :attendances, through: :rel_user_products
  # has_many :wkclasses, through: :attendances
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workouts, through: :rel_workout_group_workouts

  attr_accessor :workout_ids
  after_create :create_rel_workout_group_workout
  after_update :update_rel_workout_group_workout

  def base_revenue
    attendances.map { |a| a.revenue }.inject(0, :+)
  end

  def create_rel_workout_group_workout
    workout_ids.each { |wid| RelWorkoutGroupWorkout.create(workout_group_id: id, workout_id: wid) }
  end

  def update_rel_workout_group_workout
    # toimprove
    rel_workout_group_workouts.each { |rel| rel.destroy }
    workout_ids.each { |wid| RelWorkoutGroupWorkout.create(workout_group_id: id, workout_id: wid) }
  end
end
