require 'test_helper'

class Client::WaitingControllerTest < ActionDispatch::IntegrationTest
  def setup
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    # @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    # @admin = accounts(:admin)
    @account_other_client = accounts(:client1)
    @other_client = @account_other_client.client
    @other_client_purchase = @other_client.purchases.last
    # @account3 = accounts(:client_for_ongoing_trial)
    # @purchase3 = @account3.client.purchases.last
    # @account4 = accounts(:client_for_fixed)
    # @purchase4 = @account4.client.purchases.last
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'should redirect when client (somehow) tries to joins waiting list when class not at capacity' do
    log_in_as(@account_client)
    assert_difference 'Waiting.all.size', 0 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                           purchase_id: @purchase.id,
                                           booking_day: 0,
                                           booking_section: 'group' }
    end

    assert_redirected_to login_path
    assert_equal [['Only make waiting list changes through the dashboard.']], flash[:warning]
  end

  test 'should redirect when client (somehow) tries to joins waiting list for a class they dont have a valid package for' do
    @tomorrows_class_early.update(max_capacity: 0)
    @purchase.update(status: 'expired')
    log_in_as(@account_client)
    assert_difference 'Waiting.all.size', 0 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                           purchase_id: @purchase.id,
                                           booking_day: 0,
                                           booking_section: 'group' }
    end

    assert_redirected_to login_path
    assert_equal [['Only make waiting list changes through the dashboard.']], flash[:warning]
  end

  test 'should redirect when client (somehow) tries to add another client to the wating list' do
    @tomorrows_class_early.update(max_capacity: 0)
    log_in_as(@account_client)
    assert_difference 'Waiting.all.size', 0 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                           purchase_id: @other_client_purchase.id,
                                           booking_day: 0,
                                           booking_section: 'group' }
    end

    assert_redirected_to login_path
    assert_equal [['Only make waiting list changes through the dashboard.']], flash[:warning]
  end

  test 'client legitimately joins waiting list when class at capacity' do
    @tomorrows_class_early.update(max_capacity: 0)
    log_in_as(@account_client)

    assert_difference 'Waiting.all.size', 1 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                           purchase_id: @purchase.id,
                                           booking_day: 0,
                                           booking_section: 'group' }
    end

    assert_redirected_to client_book_path(@client.id, booking_section: 'group')
    assert_equal [["You have been added to the waiting list for #{@tomorrows_class_early.name}. You will be sent a message if a spot opens up."]], flash[:success]
  end

  test 'client legitimately joins waiting list when class at capacity (having previously cancelled early)' do
    log_in_as(@account_client)
    # book class, then cancel early
    assert_difference '@client.attendances.size', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id },
                                             booking_section: 'group' }
    end
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_difference '@client.attendances.no_amnesty.size', -1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    assert @attendance.status, 'cancelled early'

    # set class to capacity
    @tomorrows_class_early.update(max_capacity: 0)

    assert_difference 'Waiting.all.size', 1 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                           purchase_id: @purchase.id,
                                           booking_day: 0,
                                           booking_section: 'group' }
    end

    assert_redirected_to client_book_path(@client.id, booking_section: 'group')
    assert_equal [["You have been added to the waiting list for #{@tomorrows_class_early.name}. You will be sent a message if a spot opens up."]], flash[:success]
  end

  test 'client legitimately leaves waiting list' do
    waiting = Waiting.create!(wkclass_id: @tomorrows_class_early.id, purchase_id: @purchase.id)
    log_in_as(@account_client)
    assert_difference 'Waiting.all.size', -1 do
      delete client_waiting_path(waiting, booking_section: 'group')
    end

    assert_redirected_to client_book_path(@client.id, booking_section: 'group')
    assert_equal [['You have been removed from the waiting list for HIIT.']], flash[:success]
  end

  test 'should redirect when client (somehow) tries to remove another client from the wating list' do
    waiting = Waiting.create!(wkclass_id: @tomorrows_class_early.id, purchase_id: @other_client_purchase.id)
    log_in_as(@account_client)
    assert_difference 'Waiting.all.size', 0 do
      delete client_waiting_path(waiting, booking_section: 'group')
    end

    assert_redirected_to login_path
    assert_equal [['Only make waiting list changes through the dashboard.']], flash[:warning]
  end
end
