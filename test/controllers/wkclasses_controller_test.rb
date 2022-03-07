require "test_helper"

class WkclassesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client1 = accounts(:client1)
    @client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @partner1 = accounts(:partner1)
    @partner2 = accounts(:partner2)
    @time = '2022-02-13 10:30:00'
    @workout = workouts(:hiit)
    @instructor = instructors(:amit)
    @wkclass1 = wkclasses(:wkclass1)
  end

  test "should redirect index when not logged in as junioradmin or more senior" do
    get admin_wkclasses_url
    assert_redirected_to login_path
    log_in_as(@client1)
    get admin_wkclasses_url
    assert_redirected_to login_path
    log_in_as(@partner1)
    get admin_wkclasses_url
    assert_redirected_to login_path
  end

  test "should redirect new when not logged in as junioradmin or more senior" do
    get new_admin_wkclass_url
    assert_redirected_to login_path
    log_in_as(@client1)
    get new_admin_wkclass_url
    assert_redirected_to login_path
    log_in_as(@partner1)
    get new_admin_wkclass_url
    assert_redirected_to login_path
  end

  test 'should redirect create when not logged in as junior admin or more senior' do
    assert_no_difference 'Wkclass.count' do
      post admin_wkclasses_path, params: { wkclass: { workout_id: @workout.id, start_time: @time, instructor_id: @instructor.id } }
    end
    assert_redirected_to login_path
    log_in_as(@client1)
    assert_no_difference 'Wkclass.count' do
      post admin_wkclasses_path, params: { wkclass: { workout_id: @workout.id, start_time: @time, instructor_id: @instructor.id } }
    end
    assert_redirected_to login_path
    log_in_as(@partner1)
    assert_no_difference 'Wkclass.count' do
      post admin_wkclasses_path, params: { wkclass: { workout_id: @workout.id, start_time: @time, instructor_id: @instructor.id } }
    end
    assert_redirected_to login_path
  end

  test 'should redirect show when not logged in as junior admin or more senior' do
    get admin_wkclass_path(@wkclass1)
    assert_redirected_to login_path
    log_in_as(@client1)
    get admin_wkclass_path(@wkclass1)
    assert_redirected_to login_path
    log_in_as(@partner1)
    get admin_wkclass_path(@wkclass1)
    assert_redirected_to login_path
  end

  test 'should redirect edit when not logged in as junior admin or more senior' do
    get edit_admin_wkclass_path(@wkclass1)
    assert_redirected_to login_path
    log_in_as(@client1)
    get edit_admin_wkclass_path(@wkclass1)
    assert_redirected_to login_path
    log_in_as(@partner2)
    get edit_admin_wkclass_path(@wkclass1)
    assert_redirected_to login_path
  end

  test 'should redirect update when not logged in as junior admin or more senior' do
    patch admin_wkclass_path(@wkclass1), params: { wkclass: { start_time: '2021-09-23 10:30:00' } }
    assert_redirected_to login_path
    log_in_as(@client1)
    patch admin_wkclass_path(@wkclass1), params: { wkclass: { start_time: '2021-09-23 10:30:00' } }
    assert_redirected_to login_path
    log_in_as(@partner2)
    patch admin_wkclass_path(@wkclass1), params: { wkclass: { start_time: '2021-09-23 10:30:00' } }
    assert_redirected_to login_path
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    assert_no_difference 'Wkclass.count' do
      delete admin_wkclass_path(@wkclass1)
    end
    assert_redirected_to login_path
    log_in_as(@client1)
    assert_no_difference 'Wkclass.count' do
      delete admin_wkclass_path(@wkclass1)
    end
    assert_redirected_to login_path
    log_in_as(@partner2)
    assert_no_difference 'Wkclass.count' do
      delete admin_wkclass_path(@wkclass1)
    end
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    assert_no_difference 'Wkclass.count' do
      delete admin_wkclass_path(@wkclass1)
    end
    assert_redirected_to login_path
  end

end
