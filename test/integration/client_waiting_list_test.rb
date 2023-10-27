require "test_helper"

class ClientWaitingListTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @purchase = @client.purchases.last
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @tomorrows_class_late = wkclasses(:wkclass_for_booking_late)
    @admin = accounts(:admin)
    @account_other_client = accounts(:client_for_fixed)
    @other_client = @account_other_client.client
    @other_client_purchase = @other_client.purchases.last
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
  end
 
  test "waiting list add/remove links and images appears correctly as class capacity changes/client joins/leaves waiting list" do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select "a:match('href', ?)", /#{client_waitings_path}[?]/, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/waiting.*}, count: 0
    assert_select "a:match('href', ?)", /#{client_waitings_path}\//, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/remove.*}, count: 0          
    # eg from response
    # img class=\"table_icon mx-auto\" src=\"/assets/waiting-f7f309392d89259b5c130df83a451161b13f35a76e2f5dc11e05fcf920b4d234.png\
    
    # make 1 class full
    @tomorrows_class_early.update(max_capacity: 0)
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select "a:match('href', ?)", /#{client_waitings_path}[?]/, count: 1
    assert_select "img:match('src', ?)", %r{.*assets/waiting.*}, count: 1
    assert_select "a:match('href', ?)", /#{client_waitings_path}\//, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/remove.*}, count: 0

    # client joins waiting list
    assert_difference 'Waiting.all.size', 1 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                          purchase_id: @purchase.id,
                                          booking_day: 0,
                                          booking_section: 'group' }
    end

    follow_redirect!

    assert_template 'client/clients/book'
    assert_select "a:match('href', ?)", /#{client_waitings_path}[?]/, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/waiting.*}, count: 0                                   
    assert_select "a:match('href', ?)", /#{client_waiting_path(Waiting.last)}/, count: 1
    assert_select "img:match('src', ?)", %r{.*assets/remove.*}, count: 1

  # client leaves waiting list
    assert_difference 'Waiting.all.size', -1 do
      delete client_waiting_path(Waiting.last, booking_section: 'group')
    end

    follow_redirect!

    assert_template 'client/clients/book'
    assert_select "a:match('href', ?)", /#{client_waitings_path}[?]/, count: 1
    assert_select "img:match('src', ?)", %r{.*assets/waiting.*}, count: 1     
    assert_select "a:match('href', ?)", /#{client_waiting_path(Waiting.last)}/, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/remove.*}, count: 0
  end

  test "waiting list add/remove links and images appears correctly when other client fills class" do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select "a:match('href', ?)", /#{client_waitings_path}[?]/, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/waiting.*}, count: 0
    assert_select "a:match('href', ?)", /#{client_waitings_path}\//, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/remove.*}, count: 0

    @tomorrows_class_early.update(max_capacity: 1)
    # other client fills class
    log_in_as(@account_other_client)
    assert_difference '@other_client.attendances.no_amnesty.size', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @other_client_purchase.id },
                                            booking_section: 'group' }
    end
    
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select "a:match('href', ?)", /#{client_waitings_path}[?]/, count: 1
    assert_select "img:match('src', ?)", %r{.*assets/waiting.*}, count: 1
    assert_select "a:match('href', ?)", /#{client_waitings_path}\//, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/remove.*}, count: 0
  end

  test "waiting list add/remove links and images appears correctly when space opens up (after client has previously cancelled early)" do
    log_in_as(@account_client)
    # book class, then cancel early
    assert_difference '@client.attendances.size', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id },
                                             booking_section: 'group' }
    end
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @client)
    assert_difference '@client.attendances.amnesty.size', 1 do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end
    assert @attendance.status, 'cancelled early'

    # other client fills class
    @tomorrows_class_early.update(max_capacity: 1)
    log_in_as(@account_other_client)
    assert_difference '@other_client.attendances.size', 1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                            purchase_id: @other_client_purchase.id },
                                            booking_section: 'group' }
    end

    # client joins waiting list
    log_in_as(@account_client)    
    assert_difference 'Waiting.all.size', 1 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                          purchase_id: @purchase.id,
                                          booking_day: 0,
                                          booking_section: 'group' }
    end    

    # spot opens up (other client cancels)
    @attendance = Attendance.applicable_to(@tomorrows_class_early, @other_client)
    log_in_as(@account_other_client)    
    assert_difference '@other_client.attendances.amnesty.size', 1 do
      patch admin_attendance_path(@attendance), params: { attendance: { id: @attendance.id } }
    end    
    
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select "a:match('href', ?)", /#{admin_attendances_path}\//, count: 1 
    assert_select "img:match('src', ?)", %r{.*assets/add.*}, count: 3 # 22/4, 22/4, 24/4
    assert_select "a:match('href', ?)", /#{client_waitings_path}[?]/, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/waiting.*}, count: 0
    assert_select "a:match('href', ?)", /#{client_waitings_path}\//, count: 1
    assert_select "img:match('src', ?)", %r{.*assets/remove.*}, count: 0
    assert_select "img:match('src', ?)", %r{.*assets/delete.*}, count: 1
  end

  test "client removed from waiting list when booking a class while on waiting list" do
    @tomorrows_class_early.update(max_capacity: 0)
    log_in_as(@account_client)
    assert_difference 'Waiting.all.size', 1 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                          purchase_id: @purchase.id,
                                          booking_day: 0,
                                          booking_section: 'group' }
    end
    @tomorrows_class_early.update(max_capacity: 1)

    assert_difference 'Waiting.all.size', -1 do
      post admin_attendances_path, params: { attendance: { wkclass_id: @tomorrows_class_early.id,
                                                           purchase_id: @purchase.id },
                                             booking_section: 'group' }
    end


  end

  # this test demonstrates the flash message associated with the Whatsapp class is triggered without explicitly demonstrating the send_whatsapp method fired
  # I tried to stub the instance method send_whatsapp but had difficulties stubbing an instance method (distinct from a class method)
  # when clients trigger a waiting list blast they (obviously) don't receive a flash about it, so these cases are untested (aka manually tested) for now
  # note the  
  test "waiting list notified when spot opens up (due to capacity increase)" do
    @tomorrows_class_early.update(max_capacity: 0)
    log_in_as(@account_client)
    assert_difference 'Waiting.all.size', 1 do
      post client_waitings_path, params: { wkclass_id: @tomorrows_class_early.id,
                                          purchase_id: @purchase.id,
                                          booking_day: 0,
                                          booking_section: 'group' }
    end    

    # spot opens up
    log_in_as(@admin)
    follow_redirect! # clear out flashes from these requests

    # Whatsapp.new.stub :send_whatsapp, { whatsapp_sent: true } do
    patch admin_wkclass_path(@tomorrows_class_early), params: { wkclass: { max_capacity: 1 } }
    assert_equal [['waiting list blast message sent by Whatsapp to +916193111111']], flash[:warning]    
    assert_equal [['Class was successfully updated']], flash[:success]    

    # assert_equal 1, @tomorrows_class_early.reload.max_capacity
   end  
end
