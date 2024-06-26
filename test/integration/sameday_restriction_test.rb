require 'test_helper'

class SamedayRestrictionTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    # @purchase = @client.purchases.last
    @purchase = purchases(:ekta_unlimited)
    @purchase2 = purchases(:ekta_nutrition)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @admin = accounts(:admin)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'cant book 2 classes (with one unlimited package) on same day' do
    log_in_as(@account_client)
    # book a class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }

    # client attempts to book 2nd class on same day (with one unlimited package)
    assert_difference '@client.bookings.size', 0 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end

    # admin attempts to book 2nd class on same day (with one unlimited package)
    log_in_as(@admin)
    assert_difference '@client.bookings.size', 0 do
      post bookings_path, params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end

    # cancel class early
    @booking = Booking.applicable_to(@tomorrows_class_early, @client)
    patch booking_cancellation_path(@booking), params: { booking: { id: @booking.id, status: 'cancelled early' } }

    # client books 2nd class same day after early cancellation of first
    log_in_as(@account_client)
    assert_difference '@client.bookings.no_amnesty.size', 1 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end

    # client attempts to book 2nd class on same day (with a different unlimited package)
    assert_difference '@client.bookings.size', 1 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase2.id } }
    end
  end

  test 'client can book 2nd class on same day after cancelling first class late (with amnesty)' do
    log_in_as(@account_client)
    # book a class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    # client cancels late (with amnesty)
    travel_to(@tomorrows_class_early.start_time - 10.minutes)
    @booking = Booking.applicable_to(@tomorrows_class_early, @client)
    patch client_update_booking_path(@client, @booking)

    # client books 2nd class same day after late cancellation (with amnesty) of first
    assert_difference '@client.bookings.no_amnesty.size', 1 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'client can (now) book 2nd class on same day after cancelling first class late (without amnesty)' do
    log_in_as(@account_client)
    # book a class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }

    # bypass late cancellation amnesty
    @purchase.update(late_cancels: 5)

    # client cancels late
    travel_to(@tomorrows_class_early.start_time - 10.minutes)
    @booking = Booking.applicable_to(@tomorrows_class_early, @client)
    patch client_update_booking_path(@client, @booking)

    # client succeeds in booking 2nd class same day after late cancellation of first (even with amnesty used up)
    assert_difference '@client.bookings.no_amnesty.size', 1 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'client can book 2nd class on same day after no show on first class (with amnesty)' do
    log_in_as(@account_client)
    # book a class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }

    # client no shows
    log_in_as(@admin)
    @booking = Booking.applicable_to(@tomorrows_class_early, @client)
    patch booking_cancellation_path(@booking), params: { booking: { id: @booking.id, status: 'no show' } }

    # client books 2nd class same day after late cancellation of first
    log_in_as(@account_client)
    assert_difference '@client.bookings.no_amnesty.size', 1 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'client (now) can book 2nd class on same day after no show on first class (without amnesty)' do
    log_in_as(@account_client)
    # book a class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }

    # bypass no show amnesty
    @purchase.update(no_shows: 5)

    # client no shows
    log_in_as(@admin)
    @booking = Booking.applicable_to(@tomorrows_class_early, @client)
    patch booking_cancellation_path(@booking), params: { booking: { id: @booking.id, status: 'no show' } }

    # client succeeds in booking 2nd class same day after no show of first (even with amnesty used up)
    log_in_as(@account_client)
    assert_difference '@client.bookings.no_amnesty.size', 1 do
      post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'can rebook 2nd class after cancelling it early and then booking and no showing (with amnesty) on first class' do
    log_in_as(@account_client)
    # book late class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_late.id,
                                                         purchase_id: @purchase.id },
                                           booking_section: 'group' }

    assert_redirected_to client_bookings_path(@client.id, booking_section: 'group', major_change: false)
    assert_equal [['Booked for HIIT on Friday']], flash[:success]
    # cancel late class early
    @booking = Booking.applicable_to(@tomorrows_class_late, @client)
    patch client_update_booking_path(@client, @booking)

    # book early class
    post client_create_booking_path(@client), params: { booking: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    # no show early class
    log_in_as(@admin)
    @booking = Booking.applicable_to(@tomorrows_class_early, @client)
    patch booking_cancellation_path(@booking), params: { booking: { id: @booking.id, status: 'no show' } }

    # client rebooks late class
    log_in_as(@account_client)
    assert_difference '@client.bookings.no_amnesty.size', 1 do
      @booking = Booking.applicable_to(@tomorrows_class_late, @client)
      patch client_update_booking_path(@client, @booking)
    end
  end
end
