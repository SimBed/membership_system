require "test_helper"

class ClientsBookTest < ActionDispatch::IntegrationTest
  def setup
    # travel_to Date.parse('20 April 2022')
    @account_client = accounts(:client_for_booking)
    @client = @account_client.clients.first
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @admin = accounts(:admin)
    travel_to (@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'test new booking by client' do
    log_in_as(@account_client)
    assert_difference 'Attendance.count', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id } }
    end
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 'booked', @attendance.status
    assert_redirected_to client_book_path(@client.id)
    # assert_redirected_to "/client/clients/#{@client.id}/book"
    assert_not flash.empty?
  end

  test 'cancel booking early' do
    log_in_as(@account_client)
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_difference 'Attendance.count', 0 do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 'cancelled early', @attendance.status
    assert_redirected_to client_book_path(@client.id)
    assert_not flash.empty?
  end

  test 'cancel booking late' do
    log_in_as(@account_client)
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to (@tomorrows_class_early.start_time - 1.hour)
    assert_difference 'Attendance.count', 0 do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 'cancelled late', @attendance.status
    assert_redirected_to client_book_path(@client.id)
    assert_not flash.empty?
  end

  test '2nd booking on same day' do
    log_in_as(@account_client)
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    assert_difference 'Attendance.count', 0 do
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                         purchase_id: @purchase.id } }
    end
    assert_redirected_to client_book_path(@client.id)
    # assert_redirected_to "/client/clients/#{@client.id}/book"
    assert_not flash.empty?
  end

  test 'rebook same day after cancel early' do
    log_in_as(@account_client)
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    assert_difference 'Attendance.count', 1 do
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                         purchase_id: @purchase.id } }
    end
    assert_redirected_to client_book_path(@client.id)
    assert_not flash.empty?
  end

  test 'rebook same day after cancel late' do
    log_in_as(@account_client)
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to (@tomorrows_class_early.start_time - 1.hour)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    assert_difference 'Attendance.count', 1 do
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                         purchase_id: @purchase.id } }
    end
    assert_redirected_to client_book_path(@client.id)
    assert_not flash.empty?
  end

  test 'change booking from booked after class started (before admin updates attendance)' do
    log_in_as(@account_client)
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to (@tomorrows_class_early.start_time + 5.minutes)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    assert_equal 'booked', @attendance.reload.status
    assert_redirected_to client_book_path(@client.id)
    assert_equal "Booking for #{@tomorrows_class_early.name} not changed. Deadline to make changes has passed", flash[:warning]
  end

  test 'change booking after no show' do
    log_in_as(@account_client)
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to (@tomorrows_class_early.start_time + 5.minutes)
    log_in_as(@admin)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 'no show', @attendance.status
    log_in_as(@account_client)
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    assert_redirected_to client_book_path(@client.id)
    assert_equal ["Booking is 'no show' and can't now be changed.", "Please contact the Space for help"], flash[:warning]
  end

  test 'boook class after reached maximum capacity' do
    wkclass_max_capacity = 4
    @tomorrows_class_early.update(max_capacity: wkclass_max_capacity)
    log_in_as(@admin)
    # admin books to max capacity
    @account_other_client = accounts(:client1)
    @other_client = @account_other_client.clients.first
    @other_client_purchase = @other_client.purchases.last
    wkclass_max_capacity.times {
        post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                             purchase_id: @other_client_purchase.id } }
                               }
    assert_equal @tomorrows_class_early.attendances.provisional.count, wkclass_max_capacity
    # client attempts to book
    log_in_as(@account_client)
    assert_difference 'Attendance.provisional.count', 0 do
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    end
    assert_redirected_to client_book_path(@client.id)
    assert_equal "Booking not possible. Class fully booked", flash[:warning]
    # 1 cancellation
    log_in_as(@admin)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @other_client)
    assert_difference 'Attendance.provisional.count', -1 do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'cancelled early' } }
    end
    # client now books
    log_in_as(@account_client)
    assert_difference 'Attendance.provisional.count', 1 do
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    end
    # client now cancels
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_difference 'Attendance.provisional.count', -1 do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    # class gets full again
    log_in_as(@admin)
    assert_difference 'Attendance.provisional.count', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                             purchase_id: @other_client_purchase.id } }
                                                        end
    # client attempts to rebook
    log_in_as(@account_client)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_difference 'Attendance.provisional.count', 0 do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    assert_equal "Rebooking not possible. Class fully booked", flash[:warning]
  end

  test 'client cant amend booking more than 3 times' do
    log_in_as(@account_client)
    # book
    post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                          purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 0, @attendance.amendment_count
    # cancel
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 1, @attendance.amendment_count
    # rebook
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 2, @attendance.amendment_count
    # cancel again
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 3, @attendance.amendment_count
    # re-re-book should fail
    patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_equal 3, @attendance.amendment_count
    assert_not_equal 'booked', @attendance.status
    assert_redirected_to client_book_path(@client.id)
    assert_equal ["Change not possible. Too many prior amendments.",
                  "Please contact the Space for help"], flash[:warning]
  end
end
