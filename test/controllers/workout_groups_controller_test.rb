require "test_helper"

class WorkoutGroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workout_group = workout_groups(:one)
  end

  test "should get index" do
    get workout_groups_url
    assert_response :success
  end

  test "should get new" do
    get new_workout_group_url
    assert_response :success
  end

  test "should create workout_group" do
    assert_difference('WorkoutGroup.count') do
      post workout_groups_url, params: { workout_group: { name: @workout_group.name } }
    end

    assert_redirected_to workout_group_url(WorkoutGroup.last)
  end

  test "should show workout_group" do
    get workout_group_url(@workout_group)
    assert_response :success
  end

  test "should get edit" do
    get edit_workout_group_url(@workout_group)
    assert_response :success
  end

  test "should update workout_group" do
    patch workout_group_url(@workout_group), params: { workout_group: { name: @workout_group.name } }
    assert_redirected_to workout_group_url(@workout_group)
  end

  test "should destroy workout_group" do
    assert_difference('WorkoutGroup.count', -1) do
      delete workout_group_url(@workout_group)
    end

    assert_redirected_to workout_groups_url
  end
end
