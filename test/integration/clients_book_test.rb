require 'test_helper'

class ClientBookingTest < ActionDispatch::IntegrationTest
  def setup
    # travel_to Date.parse('20 April 2022')
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @admin = accounts(:admin)
    @account_other_client = accounts(:client1)
    @other_client = @account_other_client.client
    @other_client_purchase = @other_client.purchases.last
    @account3 = accounts(:client_for_ongoing_trial)
    @purchase3 = @account3.client.purchases.last
    @account4 = accounts(:client_for_fixed)
    @purchase4 = @account4.client.purchases.last
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
  end

  test 'test new booking by client' do
    log_in_as(@account_client)
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id },
                                             booking_section: 'group' }
    end
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 'booked', @attendance.status
    assert_redirected_to client_book_path(@client.id, booking_section: 'group', major_change: false)
    # assert_redirected_to "/client/clients/#{@client.id}/book"
    assert_equal [['Booked for HIIT on Friday']], flash[:success]
  end

  test 'cancel booking early' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_difference '@client.attendances.no_amnesty.size', -1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 'cancelled early', @attendance.status
    assert_redirected_to client_book_path(@client.id, limited: true)
    assert_equal [["HIIT on Friday is 'cancelled early'",
                   'There is no deduction for this change.']], flash[:primary]
  end

  test 'cancel booking late' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to(@tomorrows_class_early.start_time - 1.hour)
    # assert multiple things
    # https://api.rubyonrails.org/classes/ActiveSupport/Testing/Assertions.html#method-i-assert_difference
    assert_difference -> { Attendance.count } => 0, -> { Attendance.no_amnesty.size } => -1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 'cancelled late', @attendance.status
    assert_redirected_to client_book_path(@client.id, limited: true)
    assert_equal [["HIIT on Friday is 'cancelled late'",
                   'There is no deduction for this change this time.',
                   'Avoid deductions by making changes to bookings before the deadlines']], flash[:primary]
  end

  test '2nd booking on same day (both limited ie not Open Gym)' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    assert_difference 'Attendance.count', 0 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id } }
    end

    assert_redirected_to client_book_path(@client.id)
    # assert_redirected_to "/client/clients/#{@client.id}/book"
    refute_predicate flash, :empty?
  end

  test '2nd booking on same day when 2nd is limited (ie Open Gym)' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id },
                                           booking_section: 'group' }
    opengym = Wkclass.create(
      workout_id: 8,
      start_time: '2022-04-22 21:00:00',
      instructor: instructors(:amit),
      instructor_rate: instructor_rates(:amit_base),
      max_capacity: 12
    )
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      post attendances_path, params: { attendance: { wkclass_id: opengym.id,
                                                           purchase_id: @purchase.id },
                                             booking_section: 'opengym' }
    end

    assert_redirected_to client_book_path(@client.id, booking_section: 'opengym', major_change: false)
    refute_predicate flash, :empty?
  end

  test '2nd booking on same day when 1st is limited (ie Open Gym) ' do
    log_in_as(@account_client)
    opengym = Wkclass.create(
      workout_id: 8,
      start_time: '2022-04-22 21:00:00',
      instructor: instructors(:amit),
      instructor_rate: instructor_rates(:amit_base),
      max_capacity: 12
    )
    post attendances_path, params: { attendance: { wkclass_id: opengym.id,
                                                         purchase_id: @purchase.id } }
    assert_difference '@client.attendances.no_amnesty.size', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id }, booking_section: 'group' }
    end

    assert_redirected_to client_book_path(@client.id, booking_section: 'group', major_change: false)
    refute_predicate flash, :empty?
  end

  test 'book same class in quick succession (double-click)' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    assert_difference 'Attendance.count', 0 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id } }
    end

    assert_redirected_to client_book_path(@client.id)
    refute_predicate flash, :empty?
  end

  test 'rebook same day after cancel early' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    assert_difference 'Attendance.count', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id },
                                             booking_section: 'group' }
    end

    assert_redirected_to client_book_path(@client.id, booking_section: 'group', major_change: false)
    assert_equal [['Booked for HIIT on Friday']], flash[:success]
  end

  test 'rebook same day after cancel late' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to(@tomorrows_class_early.start_time - 1.hour)
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    assert_difference 'Attendance.count', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_late.id,
                                                           purchase_id: @purchase.id },
                                             booking_section: 'group' }
    end

    assert_redirected_to client_book_path(@client.id, booking_section: 'group', major_change: false)
    refute_predicate flash, :empty?
  end

  test 'change booking from booked after class started (before admin updates attendance)' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to(@tomorrows_class_early.start_time + 5.minutes)
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }

    assert_equal 'booked', @attendance.reload.status
    assert_redirected_to client_book_path(@client.id)
    assert_equal [["Booking for #{@tomorrows_class_early.name} not changed. Deadline to make changes has passed"]],
                 flash[:secondary]
  end

  test 'change booking after no show' do
    log_in_as(@account_client)
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    travel_to(@tomorrows_class_early.start_time + 5.minutes)
    log_in_as(@admin)
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id, status: 'no show' } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 'no show', @attendance.status
    log_in_as(@account_client)
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }

    assert_redirected_to client_book_path(@client.id)
    assert_equal [["Booking is 'no show' and can't now be changed.", 'Please contact the Space for help']],
                 flash[:secondary]
  end

  test 'book class after reached maximum capacity' do
    wkclass_max_capacity = 3
    @tomorrows_class_early.update(max_capacity: wkclass_max_capacity)
    log_in_as(@admin)
    # admin books to max capacity
    # wkclass_max_capacity.times do
    #   post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
    #                                                        purchase_id: @other_client_purchase.id } }
    # end
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @other_client_purchase.id } }
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase3.id } }
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase4.id } }

    assert_equal @tomorrows_class_early.attendances.no_amnesty.count, wkclass_max_capacity
    # client attempts to book
    log_in_as(@account_client)
    assert_difference '@client.attendances.no_amnesty.count', 0 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id } }
    end

    assert_redirected_to client_book_path(@client.id)
    assert_equal [['Booking not possible. Class fully booked']], flash[:secondary]
    # 1 cancellation
    log_in_as(@admin)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @other_client)
    assert_difference 'Attendance.no_amnesty.count', -1 do
      patch attendance_path(@attendance),
            params: { attendance: { id: @attendance.id, status: 'cancelled early' } }
    end

    assert_equal @tomorrows_class_early.attendances.no_amnesty.count, wkclass_max_capacity - 1
    # client now books
    log_in_as(@account_client)
    assert_difference 'Attendance.no_amnesty.count', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id } }
    end
    # client now cancels
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_difference 'Attendance.no_amnesty.count', -1 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    # class gets full again
    log_in_as(@admin)
    assert_difference 'Attendance.no_amnesty.count', 1 do
      post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @other_client_purchase.id } }
    end
    # client attempts to rebook
    log_in_as(@account_client)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_difference 'Attendance.no_amnesty.count', 0 do
      patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end

    assert_equal [['Rebooking not possible. Class fully booked']], flash[:secondary]
  end

  test 'client cant amend booking more than 3 times' do
    log_in_as(@account_client)
    # book
    post attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                         purchase_id: @purchase.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 0, @attendance.amendment_count
    # cancel
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 1, @attendance.amendment_count
    # rebook
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 2, @attendance.amendment_count
    # cancel again
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 3, @attendance.amendment_count
    # re-re-book should fail
    patch attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)

    assert_equal 3, @attendance.amendment_count
    refute_equal 'booked', @attendance.status
    assert_redirected_to client_book_path(@client.id)
    assert_equal [['Change not possible. Too many prior amendments.',
                   'Please contact the Space for help']], flash[:secondary]
  end
end
