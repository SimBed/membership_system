require 'test_helper'

class SamedayRestrictionTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.clients.first
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @admin = accounts(:admin)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'cant book 2 classes on same day' do
    log_in_as(@account_client)
    # book a class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }

    # client attempts to book 2nd class same day
    assert_difference '@client.attendances.size', 0 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end

    # admin attempts to book 2nd class same day
    log_in_as(@admin)
    assert_difference '@client.attendances.size', 0 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end

    # cancel class early
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'cancelled early' } }

    # client books 2nd class same day after early cancellation of first
    log_in_as(@account_client)
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'can book 2nd class on same day after cancelling first class late (with amnesty)' do
    log_in_as(@account_client)
    # book a class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    # client cancels late
    travel_to(@tomorrows_class_early.start_time - 10.minutes)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }

    # client books 2nd class same day after late cancellation of first
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'can book 2nd class on same day after cancelling first class late (without amnesty)' do
    log_in_as(@account_client)
    # book a class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }

    # remove late cancellation amnesty
    assert_difference '@purchase.late_cancels', 5 do
      @purchase.update(late_cancels: 5)
    end
    # client cancels late
    travel_to(@tomorrows_class_early.start_time - 10.minutes)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }

    # client books 2nd class same day after late cancellation of first (with amnesty used up)
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'can book 2nd class on same day after no show on first class (with amnesty)' do
    log_in_as(@account_client)
    # book a class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }

    # client no shows
    log_in_as(@admin)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }

    # client books 2nd class same day after late cancellation of first
    log_in_as(@account_client)
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'can book 2nd class on same day after no show on first class (without amnesty)' do
    log_in_as(@account_client)
    # book a class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }

    # remove no show amnesty
    assert_difference '@purchase.no_shows', 5 do
      @purchase.update(no_shows: 5)
    end
    # client no shows
    log_in_as(@admin)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }

    # client books 2nd class same day after late cancellation of first
    log_in_as(@account_client)
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end
  end

  test 'can rebook 2nd class after cancelling it early and then booking and no showing on first class' do
    log_in_as(@account_client)
    # book late class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                         purchase_id: @purchase.id } }

    # cancel late class early
    @attendance = Attendance.applicable_to(@tomorrows_class_late, @client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }

    # book early class
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    # no show early class
    log_in_as(@admin)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }

    # client rebooks late class
    log_in_as(@account_client)
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      @attendance = Attendance.applicable_to(@tomorrows_class_late, @client)
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
  end
end
