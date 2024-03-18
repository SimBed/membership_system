require 'test_helper'
class WorkoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @workout = workouts(:hiit)
  end

  # no show method for workouts controller

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_workout_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get workouts_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_workout_path(@workout)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Workout.count' do
        post workouts_path, params:
         { workout: { name: 'run' } }
      end
    end
  end

  test 'should redirect update when not logged in as admin or more senior' do
    original_name = @workout.name
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      patch workout_path(@workout), params:
       { workout: { name: 'newname' } }

      assert_equal original_name, @workout.reload.name
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Workout.count' do
        delete workout_path(@workout)
      end
    end
  end
end
