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
    @inbody = workouts(:inbody)
    @instructor = instructors(:amit)
    @instructor_rate = instructor_rates(:amit_base)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
  end

  test 'class booking links appear correctly for client before and after admin adds and edits new class' do
    log_in_as(@account_client)
    follow_redirect! # logging in as client triggers redirect to booking page

    assert_template 'client/dynamic_pages/book'
    # assert_select 'a[href=?]', bookings_path, count: 2
    # i dont know where this syntax is documented, but it selects anchor elements with an href that matches the given regexs
    assert_select "a:match('href', ?)", /#{client_create_booking_path(@client)}/, count: 3 # 22/4, 22/4, 24/4
    # the path is to the create method (i.e. for a new booking, not an amendmdent to an existing booking)
    # no bookings made yet
    assert_equal 0, booking_count('booked') # test_helper.rb
    log_in_as(@admin)
    # follow_redirect!
    # add an extra wkclass within the visibility and booking window
    post wkclasses_path, params:
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
    assert_select "a:match('href', ?)", /#{bookings_path}/, count: 4 # 22/4, 22/4, 24/4, 24/4
    log_in_as(@admin)
    @wkclass = Wkclass.last
    # push the date outside of the booking window (no test yet for whether it is visible (which it should be) just not bookable)
    # wkclass_params expects to find a params[:wkclass][:instructor_rate_id] to set cost, hence the inclusion of instructor_rate_id in the patch)
    patch wkclass_path(@wkclass), params: { wkclass: deconstruct_date(@wkclass.start_time + 1.day).merge({ instructor_rate_id: @wkclass.instructor_rate_id }) } # 25/4 (booking starts on 23/4)
    # patch wkclass_path(@wkclass), params: { wkclass: { start_time: @wkclass.start_time + 1.day, instructor_rate_id: @wkclass.instructor_rate_id } } # 25/4 (booking starts on 23/4)
    log_in_as(@account_client)
    follow_redirect!
    # no booking link for the later dated wkclass
    assert_select "a:match('href', ?)", /#{bookings_path}/, count: 3 # 22/4, 22/4, 24/4
  end

  test 'class booking links appear correctly for client after making new booking' do
    log_in_as(@account_client)
    follow_redirect!
    # There is a class on 25th but booking_window_days_before defaults to 2
    assert_select "a:match('href', ?)", /#{bookings_path}/, count: 3 # 22/4, 22/4, 24/4
    assert_difference 'Booking.count', 1 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                  purchase_id: @purchase.id },
                                    booking_section: 'group' }
    end
    follow_redirect!

    assert_template 'client/dynamic_pages/book'
    # only 1 class booked but shown twice (once in group, once in my_bookings)
    assert_equal 2, booking_count('booked')
    # after booking:
    # type of link changes from post to patch
    # patch link doubles up as once in group section/once in my booking section
    # post link for other class on same day may disappear if class becomes unbookable
    # so 3 posts becomes 2 patches and 3 -1 (post to patch) -1 (same day class unbookable) = 1 post
    # example of post/patch syntax
    # post to  "/admin/bookings?booking%5Bpurchase_id%5D=824&amp;booking%5Bwkclass_id%5D=1133&amp;booking_day=1&amp;booking_section=group"
    # patch to "/admin/bookings/2139?booking_day=1&amp;booking_section=group"
    # find way to export response to file for easier debugging
    # not used in end - but note the addition of \/ [escape backslash] in the regexs if want to select for backslash
    assert_select "a:match('href', ?)", /#{bookings_path}[?]/, count: 1
    booking = Booking.where(wkclass_id: @tomorrows_class_early.id, purchase_id: @purchase.id).first

    assert_select "a:match('href', ?)", /#{booking_cancellation_path(booking)}/, count: 2
    # assert_select 'a[href=?]', booking_path(booking), count: 1
  end

  test 'class booking links appear correctly when class gets full' do
    log_in_as(@account_client)
    follow_redirect!

    assert_template 'client/dynamic_pages/book'
    assert_select "a:match('href', ?)", /#{bookings_path}/, count: 3 # 22/4, 22/4, 24/4
    # make 1 class full
    @tomorrows_class_early.update(max_capacity: 0)
    # debugger
    get client_book_path(@client)
    # classes with a booking link reduces by 1
    assert_select "a:match('href', ?)", /#{bookings_path}/, count: 2 # 22/4, 22/4, 24/4
    # 1 class shows link for waiting list
    assert_select "a:match('href', ?)", /#{client_waitings_path}/, count: 1
    # assert_select "i.bi-battery-full", 1
  end

  test 'class booking links do not include an unbookable class' do
    log_in_as(@account_client)
    follow_redirect!
    assert_select "a:match('href', ?)", /#{bookings_path}/, count: 3
    log_in_as(@admin)
    # admin adds an unbookable class
    post wkclasses_path, params:
     { wkclass:
        { workout_id: @inbody.id,
          start_time: @time,
          instructor_id: @instructor.id,
          instructor_rate_id: @instructor_rate.id,
          max_capacity: 1 } } # 24/4
    follow_redirect!
    log_in_as(@account_client)
    follow_redirect!
    # the count of classes with booking links remains unchanged
    assert_select "a:match('href', ?)", /#{bookings_path}/, count: 3 # 22/4, 22/4, 24/4
    # change the workout to a bookable one
    Wkclass.last.update(workout_id: @workout.id) # note there is no need to update the wkclasses max_capacity, the workouts default capacity is the relevant attribute that affects bookability
    get client_book_path(@client)
    # an extra class with booking link appears
    assert_select "a:match('href', ?)", /#{bookings_path}/, count: 4
  end  
end
