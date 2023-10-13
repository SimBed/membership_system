require 'test_helper'

class WkclassTest < ActiveSupport::TestCase
  def setup
    @workout = workouts(:hiit)
    @workout_pt = workouts(:pt_regular)
    @instructor = instructors(:amit)
    @instructor_rate = instructor_rates(:amit_base)
    @instructor_pt_rate = instructor_rates(:amit_pt)
    @wkclass = Wkclass.new(workout_id: @workout.id,
                           start_time: '2022-02-01 10:30:00',
                           instructor_id: @instructor.id,
                           instructor_rate: @instructor_rate)
    @wkclass_pt = Wkclass.new(workout_id: @workout_pt.id,
                              start_time: '2022-02-01 10:30:00',
                              instructor_id: @instructor.id,
                              instructor_rate: @instructor_pt_rate)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @wkclass_many_attendances = wkclasses(:wkclass_many_attendances)
    @client = clients(:aparna)
    @client2 = clients(:client_ekta_unlimited)
  end

  test 'should be valid' do
    assert_predicate @wkclass, :valid?
  end

  test 'workout/time should be unique when creating new wkclass' do
    @duplicate_class = @wkclass.dup
    @wkclass.save

    refute_predicate @duplicate_class, :valid?
  end

  test 'workout/time need not be unique when rescheduling new pt wkclass after client early cancellation of original class' do
    @duplicate_class = @wkclass_pt.dup
    @wkclass_pt.save
    Attendance.create(wkclass_id: @wkclass_pt.id,
                      purchase_id: purchases(:purchase_12C5WPT).id,
                      status: 'cancelled early')
    @duplicate_class.save

    assert_predicate @duplicate_class, :valid?
  end

  test 'show_in_bookings_for' do
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
    assert_equal [548, 568, 569, 570], Wkclass.show_in_bookings_for(@client).pluck(:id)
  end

  test 'booked_for' do
    assert_equal [], Wkclass.booked_for(@client).pluck(:id)
    Attendance.create(wkclass_id: @tomorrows_class_early.id,
                      purchase_id: @client.purchases.last.id,
                      status: 'booked')
    assert_equal [@tomorrows_class_early.id], Wkclass.booked_for(@client).pluck(:id)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
    assert_equal [@tomorrows_class_early.id], Wkclass.booked_for(@client).show_in_bookings_for(@client).pluck(:id)             
  end

  test 'chaining of booked_for and show_in_bookings_for' do # these are chained to display my_bookings to client
    Attendance.create(wkclass_id: @tomorrows_class_early.id,
                      purchase_id: @client.purchases.last.id,
                      status: 'booked')
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
    assert_equal [@tomorrows_class_early.id], Wkclass.booked_for(@client).show_in_bookings_for(@client).pluck(:id)
    # check a different client making a booking doesn't have any impact
    assert_difference 'Attendance.count', 1 do
    Attendance.create(wkclass_id: @tomorrows_class_early.id,
                      purchase_id: @client2.purchases.last.id,
                      status: 'booked')    
    end
    assert_equal [@tomorrows_class_early.id], Wkclass.booked_for(@client).show_in_bookings_for(@client).pluck(:id)    
  end

  test 'physical_attendances' do
    assert_equal 3, @wkclass_many_attendances.physical_attendances.size
  end

  test 'ethereal_attendances' do
    assert_equal 4, @wkclass_many_attendances.ethereal_attendances.size
  end

  test 'revenue' do
    assert_equal 1694, @wkclass_many_attendances.revenue
  end

  test 'at_capacity?' do
    refute_predicate @wkclass_many_attendances, :at_capacity?
  end

  test 'deletable? method' do
    @wkclass.save

    assert @wkclass.deletable?
    refute @wkclass_many_attendances.deletable?
  end
end
