class Workout < ApplicationRecord
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workout_groups, through: :rel_workout_group_workouts
  has_many :wkclasses, dependent: :destroy
  has_many :entries, dependent: :destroy
  scope :order_by_name, -> { order :name }
  scope :order_by_current, -> { order(current: :desc, name: :asc) }
  scope :current, -> { where(current: true) }
  validates :name, presence: true

  # not quite right but good enough for now. Helps prevent a PT instructor rates wrongly get selected for Space Group classes
  def group_workout?
    workout_groups.any? { |w| w.renewable?}
  end
end
