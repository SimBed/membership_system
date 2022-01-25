class Workout < ApplicationRecord
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workout_groups, through: :rel_workout_group_workouts
  has_many :wkclasses, dependent: :destroy
  scope :order_by_name, -> { order :name }
  validates :name, presence: true
end
