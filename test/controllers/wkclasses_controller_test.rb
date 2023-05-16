require 'test_helper'

class WkclassesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @time = '2022-02-13 10:30:00'
    @workout = workouts(:hiit)
    @instructor = instructors(:amit)
    @instructor_rate = instructor_rates(:amit_base)
    @wkclass = wkclasses(:wkclass_mat)
  end

  test 'should redirect new when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get new_admin_wkclass_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get admin_wkclasses_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get admin_wkclass_path(@wkclass)
      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get edit_admin_wkclass_path(@wkclass)
      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Wkclass.count' do
        post admin_wkclasses_path, params:
         { wkclass:
            { workout_id: @workout.id,
              start_time: @time,
              instructor_id: @instructor.id } }
      end
    end
  end

  test 'should redirect update when not logged in as junioradmin or more senior' do
    original_start_time = @wkclass.start_time
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      patch admin_wkclass_path(@wkclass), params:
       { wkclass:
          { workout_id: @wkclass.workout_id,
            start_time: @wkclass.start_time + 1.hour,
            instructor_id: @wkclass.instructor_id } }
      assert_equal original_start_time, @wkclass.reload.start_time
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Wkclass.count' do
        delete admin_wkclass_path(@wkclass)
      end
    end
  end

  test 'create repeat classes' do
      log_in_as(@junioradmin)
      assert_difference 'Wkclass.count', 4 do
        post admin_wkclasses_path, params:
         { wkclass:
            { workout_id: @workout.id,
              "start_time(1i)": '2022',
              "start_time(2i)": '02',
              "start_time(3i)": '13',
              "start_time(4i)": '10',
              "start_time(5i)": '30',
              instructor_id: @instructor.id,
              instructor_rate_id: @instructor_rate.id,
              repeats: 3 } }
      end
  end
end
