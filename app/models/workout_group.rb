class WorkoutGroup < ApplicationRecord
  has_many :products, dependent: :destroy
  has_many :purchases, through: :products
  has_many :bookings, through: :purchases
  has_many :expenses, dependent: :destroy
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workouts, through: :rel_workout_group_workouts
  attr_accessor :workout_ids

  validates :name, presence: true
  validates :workout_ids, presence: true
  after_create :create_rel_workout_group_workout
  after_update :update_rel_workout_group_workout
  scope :order_by_current, -> { order(current: :desc, name: :asc) }
  scope :current, -> { where(current: true) }

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

  # by_workout_group method also joins on purchase and product, but the seemingly duplicated 'includes(purchase: [:product])' reduces the database hit when
  # the revenue method is applied to each booking object in base_revenue method 
  def attendances_during(period)
    Booking.includes(purchase: [:product]).confirmed.no_amnesty.by_workout_group(name, period)
  end

  def wkclasses_during(period)
    Wkclass.in_workout_group(name).during(period)
  end

  def payments(purchase_type, period)
    return Payment.during(period) if purchase_type == 'all'

    Payment.payable_types(purchase_type).during(period)
  end

  def revenue(purchase_type, period)
    payments(purchase_type, period).sum(:amount)
  end

  def instructor_expense(period)
    Wkclass.in_workout_group(name)
           .during(period)
           .has_instructor_cost
           .sum(:instructor_cost)
  end

  def net_revenue(period)
    revenue('all', period) - instructor_expense(period)
  end

  def self.includes_workout_of(wkclass)
    joins(rel_workout_group_workouts: [:workout])
      .where(workouts: { name: wkclass.name.to_s })
    # .where("Workouts.name = ?", "#{wkclass.name}")
  end

  def workout_list
    workouts.pluck(:name).join(', ')
  end

  # def expiry_revenue(period)
  #   # purchases.fully_expired.select { |p| p.expired_in?(period) }.map(&:expiry_revenue).inject(0, :+)
  #   purchases.expired_in(period).map(&:expiry_revenue).inject(0, :+)
  # end

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
