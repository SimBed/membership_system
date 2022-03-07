require 'test_helper'

class RelWorkoutGroupWorkoutTest < ActiveSupport::TestCase
  def setup
    @rel_workout_group_workout =
      RelWorkoutGroupWorkout.new(
        workout_group_id: workout_groups(:space).id,
        workout_id: workouts(:hiit).id
      )
  end

  test 'should be valid' do
    @rel_workout_group_workout.valid?
  end
end
