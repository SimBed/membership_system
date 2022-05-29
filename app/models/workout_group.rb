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

  def net_revenue(period)
    attendances_in_period = Attendance.confirmed.by_workout_group(name, period.begin, period.end)
    base_revenue = attendances_in_period.map(&:revenue).inject(0, :+)
    expiry_revenue = expiry_revenue(period.end.strftime('%b %Y'))
    gross_revenue = base_revenue + expiry_revenue
    gst = gross_revenue * (1 - (1 / (1 + gst_rate)))
    gross_revenue - gst
  end

  def expense(period)
    fixed_expenses = Expense.by_workout_group(name, period.begin, period.end)
    total_fixed_expense = fixed_expenses.sum(:amount)
    total_instructor_expense =
      Wkclass.in_workout_group(name)
             .between(period.begin, period.end)
             .has_instructor_cost
             .sum(:instructor_cost)
    total_fixed_expense + total_instructor_expense
  end

  def profit(period)
    net_revenue(period) - expense(period)
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

  def attendances_in(revenue_date)
    attendances.in_month(Date.parse(revenue_date), Date.parse(revenue_date) + 1.month).count
  end

  def expiry_revenue(revenue_date)
    purchases.select { |p| p.expired_in?(revenue_date) }.map(&:expiry_revenue).inject(0, :+)
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
