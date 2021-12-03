class Product < ApplicationRecord
  has_many :rel_user_products, dependent: :destroy
  belongs_to :workout_group
  #has_many :rel_product_workouts, dependent: :destroy
  #has_many :workouts, through: :rel_product_workouts

  def name
    # return 'DropIn' if max_classes == 1 && "#{validity_length}#{validity_unit}" == '1D'
    "#{workout_group.name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit}"
  end

  # def type
  #   workouts_included = self.rel_product_workouts.map { |r| r.workout.name }
  #   workouts_included.count > 1 ? 'multi' : workouts_included[0]
  # end

end
