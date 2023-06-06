require 'test_helper'

class AttendancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @purchase1 = purchases(:AparnaUC1Mong)
    @attendance = attendances(:attendance_test)
    @wkclass = wkclasses(:wkclass_mat)
  end

  # no edit method for attendances controller
  # no show method for attendances controller

  test 'should redirect new when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get new_admin_attendance_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get admin_attendances_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as correct client, junior admin or more senior' do
    [nil, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Attendance.count' do
        post admin_attendances_path, params:
         { attendance:
            { wkclass_id: @wkclass.id,
              purchase_id: @purchase1.id,
              status: 'booked' } }
      end
    end
  end

  test 'should redirect update when not logged in as correct client, junioradmin or more senior' do
    original_status = @attendance.status
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      patch admin_attendance_path(@attendance), params:
       { attendance:
          { id: @attendance.id,
            status: 'attended' } }

      assert_equal original_status, @attendance.reload.status
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Attendance.count' do
        delete admin_attendance_path(@attendance)
      end
    end
  end
end
