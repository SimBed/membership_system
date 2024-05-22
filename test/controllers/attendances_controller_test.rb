require 'test_helper'

class AttendancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @purchase1 = purchases(:AparnaUC1Mong)
    @attendance = attendances(:attendance_test)
    @wkclass = wkclasses(:wkclass_mat)
  end

  # no new method for attendances controller (add directly from wkclass/:id)
  # no edit method for attendances controller
  # no show method for attendances controller

  test 'should redirect create when not logged in as correct client, junior admin or more senior' do
    [nil, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Attendance.count' do
        post attendances_path, params:
         { attendance:
            { wkclass_id: @wkclass.id,
              purchase_id: @purchase1.id,
              status: 'booked' } }
      end
    end
  end

  test 'should redirect update when not logged in as correct client, junioradmin or more senior' do
    original_status = @attendance.status
    [nil, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      patch attendance_path(@attendance), params:
       { attendance:
          { id: @attendance.id,
            status: 'attended' } }

      assert_equal original_status, @attendance.reload.status
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Attendance.count' do
        delete attendance_path(@attendance)
      end
    end
  end
end
