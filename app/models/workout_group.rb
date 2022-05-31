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

  def attendances_during(period)
    Attendance.confirmed.no_amnesty.by_workout_group(name, period)
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

  def partner_share_amount(period)
    profit(period) * partner_share.to_f / 100
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

    Rails.application.config_for(:constants)['gst_rate'].first.to_f / 100
  end

  # def attendances_in(revenue_date)
  #   attendances.in_month(Date.parse(revenue_date), Date.parse(revenue_date) + 1.month).count
  # end

  def expiry_revenue(period)
    purchases.select { |p| p.expired_in?(period) }.map(&:expiry_revenue).inject(0, :+)
  end

  def create_rel_workout_group_workout
    workout_ids.each { |wid| RelWorkoutGroupWorkout.create(workout_group_id: id, workout_id: wid) }
  end

  def update_rel_workout_group_workout
    # toimprove
    rel_workout_group_workouts.each(&:destroy)
    workout_ids.each { |wid| RelWorkoutGroupWorkout.create(workout_group_id: id, workout_id: wid) }
  end
end
