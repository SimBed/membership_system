class WorkoutGroup < ApplicationRecord
  belongs_to :partner
  has_many :products, dependent: :destroy
  has_many :purchases, through: :products
  has_many :attendances, through: :purchases
  # has_many :wkclasses, through: :attendances
  has_many :rel_workout_group_workouts, dependent: :destroy
  has_many :workouts, through: :rel_workout_group_workouts
  attr_accessor :workout_ids
  validates :name, presence: true
  validates :partner_share, presence: true
  validates :workout_ids, presence: true
  after_create :create_rel_workout_group_workout
  after_update :update_rel_workout_group_workout

  def self.includes_workout_of(wkclass)
    joins(rel_workout_group_workouts: [:workout])
    .where("Workouts.name = ?", "#{wkclass.name}")
  end

  # not used
  # def self.instructor_cost_for(workout_group_name, start_date, end_date)
  #   Wkclass.in_workout_group(workout_group_name).between(start_date,end_date)
  #          .has_instructor_cost
  #          .sum(:instructor_cost)
  # end

  def workout_list
    workouts.pluck(:name).join(', ')
  end

  def gst_rate
    return 0 if !gst_applies
    Rails.application.config_for(:constants)["gst_rate"].first.to_f / 100
  end

  # products_hash collates the relevant attributes across 3 models which define each product
  # and creates a name out of them
  # a product can then be selected from a single dropdown when adding a purchase eg 'Space 1C:1D Diwali21'
  def self.products_hash
# attributes returns an array of hashes like below and the each loop adds the name key/value pair to it.
# [{"wg_name"=>"Space",.."price"=>500,.."name"=>"Space UC:1W Diwali21"}, {...}, {...} ...]
    joins(products: [:prices])
   .select('workout_groups.name as wg_name','products.id as product_id', 'products.max_classes',
           'products.validity_length', 'products.validity_unit', 'prices.name as price_name', 'prices.price')
   .order('workout_groups.id', 'products.id')
   .map(&:attributes)
   .each { |p| p['name'] = Product.full_name(p['wg_name'], p['max_classes'],
               p['validity_length'], p['validity_unit'], p['price_name'])
          }
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
