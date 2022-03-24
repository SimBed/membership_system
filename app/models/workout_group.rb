class WorkoutGroup < ApplicationRecord
  belongs_to :partner
  has_many :products, dependent: :destroy
  has_many :purchases, through: :products
  has_many :attendances, through: :purchases
  has_many :expenses, dependent: :destroy
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workouts, through: :rel_workout_group_workouts
  attr_accessor :workout_ids
  validates :name, presence: true
  validates :partner_share, presence: true
  validates :workout_ids, presence: true
  after_create :create_rel_workout_group_workout
  after_update :update_rel_workout_group_workout
  scope :order_by_name, -> { order(:name) }

  def self.includes_workout_of(wkclass)
    joins(rel_workout_group_workouts: [:workout])
    .where("Workouts.name = ?", "#{wkclass.name}")
  end

  def workout_list
    workouts.pluck(:name).join(', ')
  end

  def gst_rate
    return 0 if !gst_applies
    Rails.application.config_for(:constants)["gst_rate"].first.to_f / 100
  end

  def attendances_in(revenue_date)
    attendances.in_month(Date.parse(revenue_date), Date.parse(revenue_date) + 1.month).count
  end

  def expiry_revenue(revenue_date)
    purchases.select { |p| p.expired_in?(revenue_date) }.map { |p| p.expiry_revenue }.inject(0, :+)
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
