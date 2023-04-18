require 'test_helper'
class WorkoutGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @account_partner2 = accounts(:partner2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @workout_group = workout_groups(:space)
    @workout = workouts(:hiit)
  end

  # no show method for workout_groups controller

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_admin_workout_group_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as partner or admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get admin_workout_groups_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as correct partner or superadmin' do
    [nil, @account_client1, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get admin_workout_group_path(@workout_group)
      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_admin_workout_group_path(@workout_group)
      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'WorkoutGroup.count' do
        post admin_workout_groups_path, params:
         { workout_group:
            { name: 'PT',
              partner_id: @account_partner1.partner.id,
              partner_share: 50,
              workout_ids: [@workout.id] } }
      end
    end
  end

  test 'should redirect update when not logged in as admin or more senior' do
    original_partner_share = @workout_group.partner_share
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      patch admin_workout_group_path(@workout_group), params:
       { workout_group:
          { name: @workout_group.name,
            partner_id: @workout_group.partner_id,
            partner_share: @workout_group.partner_share + 10,
            workout_ids: @workout_group.workouts.pluck(:id) } }
      assert_equal original_partner_share, @workout_group.reload.partner_share
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'WorkoutGroup.count' do
        delete admin_workout_group_path(@workout_group)
      end
    end
  end
end
