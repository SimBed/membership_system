require 'test_helper'

class PenaltyForUnlimitedTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @wkclass3 = wkclasses(:wkclass_for_test3)
    @wkclass4 = wkclasses(:wkclass_for_test4)
    @admin = accounts(:admin)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'amnesty then penalty after cancel unlimited package late multiple times' do
    log_in_as(@account_client)
    # book a class
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to(@tomorrows_class_early.start_time - 10.minutes)
    # cancel class late
    assert_no_difference '@purchase.penalties.size' do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end

    assert_equal 1, @purchase.reload.late_cancels

    # book a 2nd class
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_late, @client)
    travel_to(@tomorrows_class_late.start_time - 10.minutes)
    # cancel 2nd class late
    assert_no_difference '@purchase.penalties.count' do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end

    assert_equal 2, @purchase.reload.late_cancels

    # book a 3rd class
    # must be in booking_window
    travel_to(@wkclass3.start_time.beginning_of_day)
    assert_difference 'Attendance.no_amnesty.size', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @wkclass3.id,
                                                           purchase_id: @purchase.id } }
    end
    @attendance = Attendance.applicable_to(@wkclass3, @client)
    travel_to(@wkclass3.start_time - 10.minutes)
    # cancel 3rd class late
    assert_difference '@purchase.penalties.count', 1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end

    assert_equal 3, @purchase.reload.late_cancels

    # book a 4th class
    # must be in booking_window
    travel_to(@wkclass4.start_time.beginning_of_day)
    assert_difference 'Attendance.no_amnesty.size', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @wkclass4.id,
                                                           purchase_id: @purchase.id } }
    end
    @attendance = Attendance.applicable_to(@wkclass4, @client)
    travel_to(@wkclass4.start_time - 10.minutes)
    # cancel 4th class late
    assert_difference '@purchase.penalties.count', 1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end

    assert_equal 4, @purchase.reload.late_cancels
    assert_redirected_to client_book_path(@client.id, limited: true, major_change: true)
    assert_equal [["HIIT on Monday is 'cancelled late'", 'A deduction will be made to your Package.',
                   'Avoid deductions by making changes to bookings before the deadlines']], flash[:danger]
  end

  test 'warning then penalty after no show multiple times' do
    log_in_as(@admin)
    # book a class
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    # no show
    assert_no_difference '@purchase.penalties.count' do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    end

    assert_equal 1, @purchase.reload.no_shows

    # book a 2nd class (can't book same day as no show so book wkclass3)
    assert_difference 'Attendance.count', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @wkclass3.id,
                                                           purchase_id: @purchase.id } }
    end
    @attendance = Attendance.applicable_to(@wkclass3, @client)
    # no show 2nd time
    assert_difference '@purchase.penalties.count', 1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    end

    assert_equal 2, @purchase.reload.no_shows

    # assert_redirected_to client_book_path(@client.id)
    # assert_equal "Booking is 'no show' and too late to change", flash[:warning]
  end

  test 'booking after new expiry date should get cancelled following a penalty late cancellation that brings expiry date forward' do
    log_in_as(@account_client)
    # book a class
    # wkclass4 25/4/2022
    # Make adjustment to package so expiry date is 24/4/2022
    @purchase.adjustments.create(adjustment: -57)
    @purchase.update(expiry_date: @purchase.expiry_date_calc)

    assert_equal Date.parse('24/04/2022'), @purchase.expiry_date
    # book classes on 22/4/2005 and on final day of package (25/4/2022)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    post attendances_path, params: { attendance: { wkclass_id: @wkclass3.id,
                                                         purchase_id: @purchase.id } }
    # amend purchase so next late cancel will cause a penalty
    @purchase.update(late_cancels: 2)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    # cancel today's class late
    travel_to(@tomorrows_class_early.start_time - 10.minutes)
    assert_difference '@client.attendances.booked.count', -2 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'cancelled late' } }
    end
  end
end
