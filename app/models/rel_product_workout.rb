class RelProductWorkout < ApplicationRecord
  belongs_to :product
  belongs_to :workout
end
