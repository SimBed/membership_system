require 'test_helper'
class WorkoutGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @workout_group = workout_groups(:space)
    @workout = workouts(:hiit)
  end

  # no show method for workout_groups controller

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_workout_group_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get workout_groups_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get workout_group_path(@workout_group)

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_workout_group_path(@workout_group)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'WorkoutGroup.count' do
        post workout_groups_path, params:
         { workout_group:
            { name: 'PT',
              workout_ids: [@workout.id] } }
      end
    end
  end

  test 'should redirect update when not logged in as admin or more senior' do
    original_service = @workout_group.service
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      patch workout_group_path(@workout_group), params:
       { workout_group:
          { name: @workout_group.name,
            service: 'pt',
            workout_ids: @workout_group.workouts.pluck(:id) } }

      assert_equal original_service, @workout_group.reload.service
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'WorkoutGroup.count' do
        delete workout_group_path(@workout_group)
      end
    end
  end
end
