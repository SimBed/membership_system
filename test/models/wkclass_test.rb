require 'test_helper'

class WkclassTest < ActiveSupport::TestCase
  def setup
    @workout = workouts(:hiit)
    @instructor = instructors(:amit)
    @wkclass = Wkclass.new(workout_id: @workout.id,
                           start_time: '2022-02-01 10:30:00',
                           instructor_id: @instructor.id,
                           instructor_cost: 500)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @wkclass_many_attendances = wkclasses(:wkclass_many_attendances)
    @client = clients(:aparna)
  end

  test 'should be valid' do
    assert_predicate @wkclass, :valid?
  end

  test 'workout/time should be unique when creating new wkclass' do
    @duplicate_class = @wkclass.dup
    @wkclass.save
    refute_predicate @duplicate_class, :valid?
  end

  test 'show_in_bookings_for' do
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
    assert_equal [548, 568, 569, 570], Wkclass.show_in_bookings_for(@client).pluck(:id)
  end

  test 'spots_taken' do
    assert_equal 7, @wkclass_many_attendances.spots_taken.size
  end

end
