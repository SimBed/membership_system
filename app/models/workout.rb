class Workout < ApplicationRecord
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workoutgroups, through: :rel_workout_group_workouts
  belongs_to :instructor
  has_many :wkclasses
end
