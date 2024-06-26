require 'test_helper'

class PenaltyForFixedTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_fixed)
    @client = @account_client.client
    @purchase = @client.purchases.last
    @purchase_pt = purchases(:purchase_12C5WPT)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @wkclass3 = wkclasses(:wkclass_for_test3)
    @wkclass4 = wkclasses(:wkclass_for_test4)
    @wkclass_pt = wkclasses(:wkclass_pt)
    @admin = accounts(:admin)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'amnesty then class deduction after cancel fixed package late (for group client)' do
    log_in_as(@account_client)
    # book a class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @booking = Booking.applicable_to(@tomorrows_class_early, @client)
    travel_to(@tomorrows_class_early.start_time - 10.minutes)
    # cancel class late
    assert_no_difference '@purchase.penalties.count' do
      patch client_update_booking_path(@client, @booking)
    end

    assert_equal 1, @purchase.reload.late_cancels
    # first late cancel has amnesty
    assert_equal 1, @purchase.reload.bookings.size - @purchase.reload.bookings.no_amnesty.size

    # book a 2nd class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                         purchase_id: @purchase.id } }
    @booking = Booking.applicable_to(@tomorrows_class_late, @client)
    travel_to(@tomorrows_class_late.start_time - 10.minutes)
    # cancel 2nd class late
    # the decuction is a class not a duration validity penalty
    assert_no_difference '@purchase.penalties.count' do
      patch client_update_booking_path(@client, @booking)
    end

    assert_equal 2, @purchase.reload.late_cancels
    # the first late cancellation has amnesty, but not the 2nd
    assert_equal 1, @purchase.reload.bookings.size - @purchase.reload.bookings.no_amnesty.size

    # book a 3rd class
    travel_to(@wkclass3.start_time.beginning_of_day)
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @wkclass3.id,
                                                         purchase_id: @purchase.id } }

    @booking = Booking.applicable_to(@wkclass3, @client)
    travel_to(@wkclass3.start_time - 10.minutes)
    # cancel 3rd class late
    patch client_update_booking_path(@client, @booking)

    assert_equal 3, @purchase.reload.late_cancels
    assert_equal 1, @purchase.reload.bookings.size - @purchase.reload.bookings.no_amnesty.size
  end

  test 'immediate class deduction after fixed package no show' do
    log_in_as(@admin)
    # book a class
    post bookings_path, params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @booking = Booking.applicable_to(@tomorrows_class_early, @client)
    travel_to(@tomorrows_class_early.start_time - 10.minutes)
    # no show
    assert_no_difference '@purchase.penalties.count' do
      patch booking_cancellation_path(@booking), params: { booking: { id: @booking.id, status: 'no show' } }
    end

    assert_equal 1, @purchase.reload.no_shows
    # no amnesty for no show
    assert_equal 0, @purchase.reload.bookings.size - @purchase.reload.bookings.no_amnesty.size
    # book a 2nd class
    # fails because no show on same day prevents booking a second class - not as intended
    assert_difference '@purchase.bookings.size', 1 do
      post bookings_path, params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
    @booking = Booking.applicable_to(@tomorrows_class_late, @client)
    travel_to(@tomorrows_class_late.start_time - 10.minutes)
    # no show a 2nd time
    assert_no_difference '@purchase.penalties.count' do
      patch booking_cancellation_path(@booking), params: { booking: { id: @booking.id, status: 'no show' } }
    end

    assert_equal 2, @purchase.reload.no_shows
    assert_equal 0, @purchase.reload.bookings.size - @purchase.reload.bookings.no_amnesty.size
  end

  test 'immediate class deduction after cancel late (for PT client)' do
    log_in_as(@admin)
    # book a class
    post bookings_path, params: { booking: { wkclass_id: @wkclass_pt.id,
                                                         purchase_id: @purchase_pt.id } }
    @booking = Booking.applicable_to(@wkclass_pt, @purchase_pt.client)
    # cancel class late
    assert_no_difference '@purchase_pt.penalties.count' do
      patch booking_cancellation_path(@booking), params: { booking: { id: @booking.id, status: 'cancelled late' } }
    end

    assert_equal 1, @purchase_pt.reload.late_cancels
    # first late cancel has no amnesty
    assert_equal 0, @purchase_pt.reload.bookings.size - @purchase_pt.reload.bookings.no_amnesty.size
  end
end
