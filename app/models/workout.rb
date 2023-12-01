class Workout < ApplicationRecord
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workout_groups, through: :rel_workout_group_workouts
  has_many :wkclasses, dependent: :destroy
  has_many :entries, dependent: :destroy
  # NOTE: before validation callback rather than before_save (otherwise the validation will allow for example "HIIT " through when "HIIT" already exists)
  before_validation :prettify_name
  validates :name, presence: true,
                   uniqueness: { case_sensitive: false }
  scope :order_by_name, -> { order :name }
  scope :order_by_current, -> { order(current: :desc, name: :asc) }
  scope :current, -> { where(current: true) }
  scope :not_current, -> { where(current: false) }

  # Helps in #instructor method in wkclass controller prevent a PT instructor rate get selected wrongly for a Space Group class (and vice-versa)
  def group_workout?
    workout_groups.any?(&:groupex?)
  end
  
  def pt_workout?
    workout_groups.any?(&:pt?)
  end

  private

  def prettify_name
    self.name = name.strip.titleize
  end
end
