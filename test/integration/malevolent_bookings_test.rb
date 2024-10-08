require 'test_helper'
require 'bookings_helper'

class MalevolentBookingsTest < ActionDispatch::IntegrationTest
  # https://stackoverflow.com/questions/32029654/how-to-make-helper-methods-available-in-a-rails-integration-test
  include BookingsHelper
  setup do
    @admin = accounts(:admin)
    @account_client = accounts(:client_for_pilates)
    @client = @account_client.client
    # purchase is 8c5w, 6 classes attended, expiry_date 25/3/2022
    @purchase = purchases(:tina8c5wong)
    @instructor = instructors(:raki)
    @instructor_rate = instructor_rates(:raki_base)
    @psm = workouts(:psm)
  end

  test 'attempt by client to book class with provisonally expired package should fail' do
    # create 3 new classes
    log_in_as @admin
    assert_difference 'Wkclass.count', 3 do
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-19 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-20 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-21 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
    end
    follow_redirect!

    travel_to(Date.parse('March 17 2022').beginning_of_day)
    # provisionally expire purchase by booking 2 classes
    assert_difference '@purchase.bookings.count', 2 do
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[0].id,
                                                           purchase_id: @purchase.id } }
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[1].id,
                                                           purchase_id: @purchase.id } }
    end
    follow_redirect!

    assert_equal 'classes all booked', @purchase.reload.status
    # client attempts to book another class
    log_in_as @account_client
    assert_difference '@purchase.bookings.count', 0 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: Wkclass.last(3)[2].id,
                                                           purchase_id: @purchase.id } }
    end

    assert_redirected_to client_bookings_path @client
    assert_equal([['The maximum number of classes has already been booked.',
                   'Renew you Package if you wish to attend this class']], flash[:secondary])
  end

  test 'attempt by client to update class from cancelled early with provisonally expired package should fail' do
    log_in_as @admin
    assert_difference 'Wkclass.count', 3 do
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-19 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-20 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-21 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
    end
    follow_redirect!
    travel_to(Date.parse('March 17 2022').beginning_of_day)
    # provisionally expire purchase by booking 2 classes
    assert_difference '@purchase.bookings.count', 2 do
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[0].id,
                                                           purchase_id: @purchase.id } }
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[1].id,
                                                           purchase_id: @purchase.id } }
    end
    # cancel last booking
    @booking = @client.bookings.where(wkclass_id: Wkclass.last(3)[1].id).first
    patch booking_cancellation_path(@booking), params: { booking: { status: 'cancelled early' } }

    assert_equal 'ongoing', @purchase.reload.status
    # book another one instead
    post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[2].id,
                                                         purchase_id: @purchase.id } }

    assert_equal 'classes all booked', @purchase.reload.status

    # client attempts to rebook previously cancelled class
    log_in_as @account_client
    @booking = @client.bookings.where(wkclass_id: Wkclass.last(3)[1].id).first

    assert_difference '@purchase.bookings.count', 0 do
      patch client_update_booking_path(@client, @booking)
    end

    assert_redirected_to client_bookings_path @client
    assert_equal([['The maximum number of classes has already been booked.',
                   'Renew you Package if you wish to attend this class']], flash[:warning])
  end

  test 'attempt by admin to book class with provisonally expired package should fail' do
    # create 3 new classes
    log_in_as @admin
    assert_difference 'Wkclass.count', 3 do
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-19 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-20 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-21 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
    end
    follow_redirect!

    travel_to(Date.parse('March 17 2022').beginning_of_day)
    # provisionally expire purchase by booking 2 classes
    assert_difference '@purchase.bookings.count', 2 do
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[0].id,
                                                           purchase_id: @purchase.id } }
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[1].id,
                                                           purchase_id: @purchase.id } }
    end

    assert_equal 'classes all booked', @purchase.reload.status

    # admin attempts to book another class
    assert_difference '@purchase.bookings.count', 0 do
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[2].id,
                                                           purchase_id: @purchase.id } }
    end

    assert_redirected_to wkclass_path(Wkclass.last(3)[2])
    assert_equal([['The maximum number of classes has already been booked']], flash[:warning])
  end

  test 'admin should be able to make amendment to booking for provisonally expired package when change wont improve package terms' do
    # create 3 new classes
    log_in_as @admin
    assert_difference 'Wkclass.count', 3 do
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-19 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-20 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-21 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
    end
    follow_redirect!

    travel_to(Date.parse('March 17 2022').beginning_of_day)
    # provisionally expire purchase by booking 2 classes
    assert_difference '@purchase.bookings.count', 2 do
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[0].id,
                                                           purchase_id: @purchase.id } }
      post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[1].id,
                                                           purchase_id: @purchase.id } }
    end
    # cancel last booking
    @booking = @client.bookings.where(wkclass_id: Wkclass.last(3)[1].id).first
    patch booking_cancellation_path(@booking), params: { booking: { status: 'cancelled early' } }

    assert_equal 'ongoing', @purchase.reload.status
    # book another one instead
    post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[2].id,
                                                         purchase_id: @purchase.id } }

    assert_equal 'classes all booked', @purchase.reload.status

    # admin corrects class incorrecly logged as 'cancelled early' to 'cancelled late' (for which there is amnesty)
    assert_difference '@booking.reload.amendment_count', 1 do
      patch booking_cancellation_path(@booking), params: { booking: { status: 'cancelled late' } }
    end
    assert_redirected_to wkclass_path @booking.wkclass, link_from: 'wkclasses_index'
    assert_equal([["Tina Dehal's booking was successfully updated to cancelled late"]], flash[:success])
  end

  test 'admin should not be able to make amendment to booking for provisonally expired package when change will improve package terms' do
    # create 3 new classes
    log_in_as @admin
    assert_difference 'Wkclass.count', 3 do
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-19 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-20 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
      post wkclasses_path,
           params: { wkclass: { workout_id: @psm.id, start_time: '2022-03-21 10:30:00', instructor_id: @instructor.id, instructor_rate_id: @instructor_rate.id, max_capacity: 6 } }
    end
    follow_redirect!

    # remove late_cancellation amnesty from purchase
    @purchase.update(late_cancels: Setting.amnesty_limit[:group][:late_cancels][@purchase.product_type])

    travel_to(Date.parse('March 17 2022').beginning_of_day)
    # provisionally expire purchase by booking 2 classes
    post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[0].id,
                                                         purchase_id: @purchase.id } }
    post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[1].id,
                                                         purchase_id: @purchase.id } }

    # last booking cancelled late (but incorrectly set to cancelled early)
    @booking = @client.bookings.where(wkclass_id: Wkclass.last(3)[1].id).first
    patch booking_cancellation_path(@booking), params: { booking: { status: 'cancelled early' } }

    assert_equal 'ongoing', @purchase.reload.status
    # book another one instead (wouldn't be allowed if previous cancellation logged correctly)
    post bookings_path, params: { booking: { wkclass_id: Wkclass.last(3)[2].id,
                                                         purchase_id: @purchase.id } }

    assert_equal 'classes all booked', @purchase.reload.status

    # admin attempts to correct class incorrecly logged as 'cancelled early' to 'cancelled late' (for which there is no amnesty)
    assert_difference '@booking.reload.amendment_count', 0 do
      patch booking_cancellation_path(@booking), params: { booking: { status: 'cancelled late' } }
    end

    assert_redirected_to wkclass_path @booking.wkclass
    assert_equal [['The purchase has provisionally expired.',
                   'This change may not be possible without first cancelling a booking']], flash[:warning]
  end
end
