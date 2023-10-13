require 'test_helper'

class ClientBookingInterfaceTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @admin = accounts(:admin)
    @time = @tomorrows_class_early.start_time.advance(days: 2)
    @workout = workouts(:hiit)
    @instructor = instructors(:amit)
    @instructor_rate = instructor_rates(:amit_base)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
  end

  test 'class booking links appear correctly for client before and after admin adds and edits new class' do
    log_in_as(@account_client)
    follow_redirect! #logging in as client triggers redirect to booking page

    assert_template 'client/clients/book'
    # assert_select 'a[href=?]', admin_attendances_path, count: 2
    # i dont know where this syntax is documented, but it selects anchor elements with an href that matches the given regexs
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 3 # 22/4, 22/4, 24/4
    # the path is to the create method (i.e. for a new booking, not an amendmdent to an existing booking)
    # no bookings made yet
    assert_equal 0, booking_count('booked') # test_helper.rb
    log_in_as(@admin)
    # follow_redirect!
    # add an extra wkclass within the visibility and booking window
    post admin_wkclasses_path, params:
     { wkclass:
        { workout_id: @workout.id,
          start_time: @time,
          instructor_id: @instructor.id,
          instructor_rate_id: @instructor_rate.id,
          max_capacity: 12 } } # 24/4
    follow_redirect!
    log_in_as(@account_client)
    follow_redirect!
    # an extra class with booking link appears
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 4 # 22/4, 22/4, 24/4, 24/4
    log_in_as(@admin)
    @wkclass = Wkclass.last
    # push the date outside of the booking window (no test yet for whether it is visible (which it should be) just not bookable)
    # wkclass_params expects to find a params[:wkclass][:instructor_rate_id] to set cost, hence the inclusion of instructor_rate_id in the patch)
    patch admin_wkclass_path(@wkclass), params: { wkclass: { start_time: @wkclass.start_time + 1.day, instructor_rate_id: @wkclass.instructor_rate_id } } # 25/4 (booking starts on 23/4)
    log_in_as(@account_client)
    follow_redirect!
    # no booking link for the later dated wkclass
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 3 # 22/4, 22/4, 24/4
  end

  test 'class booking links appear correctly for client after making new booking' do
    log_in_as(@account_client)
    follow_redirect!
    # There is a class on 25th but booking_window_days_before defaults to 2
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 3 # 22/4, 22/4, 24/4
    assert_difference 'Attendance.count', 1 do    
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id },
                                           booking_section: 'group' }
    end
    follow_redirect!

    assert_template 'client/clients/book'
    # only 1 class booked but shown twice (once in group, once in my_bookings)
    assert_equal 2, booking_count('booked')
    # type of link changes from post to patch so one less (new) booking link after the booking (but 2 more update booking links (1 in group section/1 in my booking section))
    # note the addition of \/ [escape backslash] in the regexs to just select for post-style urls admin/attendances/... not patch style admin/attendances?...
    # this is confusing the response shows update urls like href=\"/admin/attendances?attendance%5Bpurchase_id%5D=459&amp;attendance%5Bwkclass_id%5D=548
    # whereas the browser shows them as href="/admin/attendances/2120?booking_day=1
    # however the test seems to work like this
    assert_select "a:match('href', ?)", /#{admin_attendances_path}\//, count: 2
    attendance = Attendance.where(wkclass_id: @tomorrows_class_early.id, purchase_id: @purchase.id).first
    assert_select "a:match('href', ?)", /#{admin_attendance_path(attendance)}/, count: 2
    # assert_select 'a[href=?]', admin_attendance_path(attendance), count: 1
  end

  test 'class booking links appear correctly when class gets full' do
    log_in_as(@account_client)
    follow_redirect!

    assert_template 'client/clients/book'
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 3 # 22/4, 22/4, 24/4
    # make 1 class full
    @tomorrows_class_early.update(max_capacity: 0)
    # debugger
    get client_book_path(@client)
    # classes with a booking link reduces by 1
    assert_select "a:match('href', ?)", /#{admin_attendances_path}/, count: 2 # 22/4, 22/4, 24/4
    # 1 class shows a full icon
    assert_select "i.bi-battery-full", 1
  end
end
