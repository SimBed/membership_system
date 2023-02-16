require 'test_helper'

class ClientBookingInterfaceTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.clients.first
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @admin = accounts(:admin)
    @time = @tomorrows_class_early.start_time.advance(days: 2)
    @workout = workouts(:hiit)
    @instructor = instructors(:amit)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
  end

  test 'class booking links appear correctly for client before and after admin adds and edits new class' do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    # assert_select 'a[href=?]', admin_attendances_path, count: 2
    # i dont know where this syntax is documented, but it selects anchor elements with an href that matches the given regexs
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 3 # 22/4, 22/4, 24/4
    # the path is to the create method (i.e. for a new booking, not an amendmdent to an existing booking)
    # no bookings made yet
    assert_equal 0, booking_count('booked') #test_helper.rb
    log_in_as(@admin)
    # follow_redirect!
    # add an extra wkclass within the visibility and booking window
    post admin_wkclasses_path, params:
     { wkclass:
        { workout_id: @workout.id,
          start_time: @time,
          instructor_id: @instructor.id } } # 24/4
    follow_redirect!
    log_in_as(@account_client)
    follow_redirect!
    # an extra class with booking link appears
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 4 # 22/4, 22/4, 24/4, 24/4
    log_in_as(@admin)
    @wkclass = Wkclass.last
    # push the date outside of the booking window (no test yet for whether it is visible (which it should be) just not bookable)
    patch admin_wkclass_path(@wkclass), params: { wkclass: { start_time: @wkclass.start_time + 1.day } } # 25/4 (booking starts on 23/4)
    log_in_as(@account_client)
    follow_redirect!
    # no booking link for the later dated wkclass
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 3 # 22/4, 22/4, 24/4
  end

  test 'class booking links appear correctly for client after making new booking' do
    log_in_as(@account_client)
    follow_redirect!
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    follow_redirect!
    assert_template 'client/clients/book'
    assert_equal 1, booking_count('booked')
    # type of link changes from post to patch so one less (new) booking link after the booking
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 2
    attendance = Attendance.where(wkclass_id: @tomorrows_class_early.id, purchase_id: @purchase.id).first
    assert_select 'a[href=?]', admin_attendance_path(attendance), count: 1
  end
end
