class Product < ApplicationRecord
  has_many :purchases, dependent: :destroy
  belongs_to :workout_group

  def name
    "#{workout_group.name} #{max_classes < 1000 ? max_classes : 'U'}C:#{validity_length}#{validity_unit}"
  end

  # def type
  #   workouts_included = self.rel_product_workouts.map { |r| r.workout.name }
  #   workouts_included.count > 1 ? 'multi' : workouts_included[0]
  # end

end
