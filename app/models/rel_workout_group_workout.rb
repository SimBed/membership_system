class RelWorkoutGroupWorkout < ApplicationRecord
  belongs_to :workout_group
  belongs_to :workout
end
