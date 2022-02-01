require "test_helper"

class WkclassTest < ActiveSupport::TestCase
  def setup
    @instructor = instructors(:Aadrak)
    @workout = workouts(:HIIT)
    @wkclass = Wkclass.new(workout_id: @workout.id, start_time: '2022-02-01 10:30:00', instructor_id: @instructor.id, instructor_cost: 0)
  end

  test 'should be valid' do
    assert @wkclass.valid?
  end
end
