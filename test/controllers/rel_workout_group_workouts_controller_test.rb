require "test_helper"

class RelWorkoutGroupWorkoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rel_workout_group_workout = rel_workout_group_workouts(:one)
  end

  test "should get index" do
    get rel_workout_group_workouts_url
    assert_response :success
  end

  test "should get new" do
    get new_rel_workout_group_workout_url
    assert_response :success
  end

  test "should create rel_workout_group_workout" do
    assert_difference('RelWorkoutGroupWorkout.count') do
      post rel_workout_group_workouts_url, params: { rel_workout_group_workout: { workout_group_id: @rel_workout_group_workout.workout_group_id, workout_id: @rel_workout_group_workout.workout_id } }
    end

    assert_redirected_to rel_workout_group_workout_url(RelWorkoutGroupWorkout.last)
  end

  test "should show rel_workout_group_workout" do
    get rel_workout_group_workout_url(@rel_workout_group_workout)
    assert_response :success
  end

  test "should get edit" do
    get edit_rel_workout_group_workout_url(@rel_workout_group_workout)
    assert_response :success
  end

  test "should update rel_workout_group_workout" do
    patch rel_workout_group_workout_url(@rel_workout_group_workout), params: { rel_workout_group_workout: { workout_group_id: @rel_workout_group_workout.workout_group_id, workout_id: @rel_workout_group_workout.workout_id } }
    assert_redirected_to rel_workout_group_workout_url(@rel_workout_group_workout)
  end

  test "should destroy rel_workout_group_workout" do
    assert_difference('RelWorkoutGroupWorkout.count', -1) do
      delete rel_workout_group_workout_url(@rel_workout_group_workout)
    end

    assert_redirected_to rel_workout_group_workouts_url
  end
end
