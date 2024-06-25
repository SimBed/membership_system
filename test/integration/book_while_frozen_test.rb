require 'test_helper'

class BookWhileFrozenTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @wkclass_post_expiry = wkclasses(:wkclass_for_test5)
    @freeze_start_date = @tomorrows_class_early.start_time.advance(days: -3)
    @freeze_end_date = @tomorrows_class_early.start_time.advance(days: 6)
    @admin = accounts(:admin)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'new booking book while frozen terminates freeze early' do
    log_in_as(@admin)

    assert_equal Date.parse('20 Jun 2022'), @purchase.expiry_date_calc
    # freeze
    assert_difference 'Freeze.count', 1 do
      post freezes_path, params:
       { freeze:
          { purchase_id: @purchase.id,
            start_date: @freeze_start_date,
            end_date: @freeze_end_date } }
    end
    follow_redirect!

    assert_equal Date.parse('30 Jun 2022'), @purchase.reload.expiry_date_calc
    assert_equal 10, @purchase.freezes.last.duration

    # book during freeze
    post bookings_path, params:
     { booking:
        { wkclass_id: @tomorrows_class_early.id,
          purchase_id: @purchase.id,
          status: 'booked' } }

    assert_equal Date.parse('23 Jun 2022'), @purchase.reload.expiry_date_calc
    assert_equal 3, @purchase.freezes.last.duration
  end

  test 'booking while frozen will cancel a class booked for a future date that is now later than the revised expiry date' do
    # in practice it doesn't seem feasible this will happen due to the short booking window...may be a freeze ends the day before expiry and on day 12 of a 14 day freeze you book for day after the freeze (expiry date) and then on day 13 book a class...
    assert_equal Date.parse('20 Jun 2022'), @purchase.expiry_date_calc
    @purchase.freezes.create(start_date: @freeze_start_date, end_date: @freeze_end_date)

    assert_equal Date.parse('30 Jun 2022'), @purchase.expiry_date_calc
    @purchase.update(expiry_date: @purchase.expiry_date_calc)
    future_booking = Booking.create(wkclass_id: @wkclass_post_expiry.id, purchase_id: @purchase.id) # 28/06/2022 (well after original expiry date)

    assert_equal 'booked', future_booking.status
    log_in_as(@account_client)
    # book during freeze, triggers earlier expiry date
    post client_create_booking_path(@client), params:
     { booking:
        { wkclass_id: @tomorrows_class_early.id,
          purchase_id: @purchase.id,
          status: 'booked' } }

    assert_equal 'cancelled early', future_booking.reload.status
  end

end
