class Product < ApplicationRecord
  has_many :rel_user_products, dependent: :destroy
  has_many :rel_product_workouts, dependent: :destroy
  has_many :workouts, through: :rel_product_workouts

  def name
    return 'DropIn' if max_classes == 1 && validity_length == 1
    "#{max_classes}C:#{validity_length}D"
  end

  def type
    workouts_included = self.rel_product_workouts.map { |r| r.workout.name }
    workouts_included.count > 1 ? 'multi' : workouts_included[0]
  end
end
