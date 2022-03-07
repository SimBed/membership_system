require 'byebug'
require "test_helper"

class WkclassTest < ActiveSupport::TestCase
  def setup
    @workout = workouts(:hiit)
    @instructor = instructors(:amit)
    @wkclass = Wkclass.new(workout_id: @workout.id,
                           start_time: '2022-02-01 10:30:00',
                           instructor_id: @instructor.id,
                           instructor_cost: 500
                          )
  end

  test 'should be valid' do
    assert @wkclass.valid?
  end

  test 'workout/time should be unique' do
   @duplicate_class = @wkclass.dup
   @wkclass.save
   refute @duplicate_class.valid?
  end
end
