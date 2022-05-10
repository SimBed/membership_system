require "test_helper"

class PenaltyForTrialTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_trial)
    @client = @account_client.clients.first
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @wkclass3 = wkclasses(:wkclass_for_test3)
    @wkclass4 = wkclasses(:wkclass_for_test4)
    @admin = accounts(:admin)
    travel_to (@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'no penalty after cancel trial late multiple times' do
    log_in_as(@account_client)
    # book a class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to (@tomorrows_class_early.start_time - 10.minutes)
    # cancel class late
    assert_no_difference '@purchase.penalties.count' do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    assert_equal 1, @purchase.reload.late_cancels

    # book a 2nd class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_late, @client)
    travel_to (@tomorrows_class_late.start_time - 10.minutes)
    # cancel 2nd class late
    assert_no_difference '@purchase.penalties.count' do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    assert_equal 2, @purchase.reload.late_cancels

    # book a 3rd class
    # must be in booking_window
    travel_to (@wkclass3.start_time.beginning_of_day)
    assert_difference 'Attendance.count', 1 do
    post admin_attendances_path, params: { attendance: { wkclass_id: @wkclass3.id,
                                                         purchase_id: @purchase.id } }
                                                       end
    @attendance = Attendance.applicable_to(@wkclass3, @client)
    travel_to (@wkclass3.start_time - 10.minutes)
    # cancel 3rd class late
    assert_no_difference '@purchase.penalties.count' do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    assert_equal 3, @purchase.reload.late_cancels

    assert_redirected_to client_book_path(@client.id)
    assert_equal ["HIIT on Sunday is 'cancelled late'", "There is no deduction for this change this time.",
                  "Avoid deductions by making changes to bookings before the deadlines"], flash[:primary]
    assert_equal 3, @purchase.attendances.confirmed.size
    assert_equal 0, @purchase.attendances.confirmed.no_amnesty.size
  end

  test 'no penalty after no show for trial multiple times' do
    log_in_as(@admin)
    # book a class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    # no show
    assert_no_difference '@purchase.penalties.count' do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    end
    assert_equal 1, @purchase.reload.no_shows

    # try and fail to book same day
    assert_difference 'Attendance.count', 0 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end

    # book a 2nd class (can't book same day as no show so book wkclass3)
    assert_difference 'Attendance.count', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @wkclass3.id,
                                                           purchase_id: @purchase.id } }
    end
    @attendance = Attendance.applicable_to(@wkclass3, @client)
    # no show 2nd time
    assert_difference '@purchase.penalties.count', 0 do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    end
    assert_equal 2, @purchase.reload.no_shows
    assert_equal 2, @purchase.attendances.confirmed.size
    assert_equal 0, @purchase.attendances.confirmed.no_amnesty.size

  end
end
