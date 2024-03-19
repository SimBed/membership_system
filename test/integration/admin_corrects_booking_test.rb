require 'test_helper'

class AdminCorrectsBookingTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @admin = accounts(:admin)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'test admin corrects no show to early cancel' do
    log_in_as(@admin)
    # admin books class
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    follow_redirect!
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    # admin (incorrectly) logs attendance as no show
    assert_difference '@purchase.reload.no_shows', 1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    end
    # admin makes correction
    assert_difference '@purchase.reload.no_shows', -1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'cancelled early' } }
    end
  end

  test 'test admin corrects no show (with a penalty) to late cancellation (without a penalty)' do
    log_in_as(@admin)
    # use up no show amnesty
    @purchase.update(no_shows: 1)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    follow_redirect!
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    # admin (incorrectly) logs attendance as no show
    assert_equal  Date.parse('20 june 2022'), @purchase.reload.expiry_date
    assert_difference '@purchase.reload.no_shows', 1 do
      # xhr redundant now use Turbo
      # patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }, xhr: true
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    end
    # admin makes correction
    assert_difference -> { @purchase.reload.expiry_date } => 2, -> { @purchase.reload.no_shows } => -1, -> { @purchase.reload.late_cancels } => 1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'cancelled late' } }
    end
  end

  test 'test admin corrects no show (with a penalty) to late cancellation (with a penalty)' do
    log_in_as(@admin)
    # use up amnesties
    @purchase.update(no_shows: 1, late_cancels: 2)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    follow_redirect!
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal Date.parse('Mon, 20 June 2022'), @purchase.reload.expiry_date
    # admin (incorrectly) logs attendance as no show
    assert_difference '@purchase.reload.no_shows', 1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    end
    # admin makes correction
    assert_difference -> { @purchase.reload.expiry_date } => 1, -> { @purchase.reload.no_shows } => -1, -> { @purchase.reload.late_cancels } => 1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'cancelled late' } }
    end
  end
end
