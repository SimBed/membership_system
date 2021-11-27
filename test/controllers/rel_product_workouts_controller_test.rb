require "test_helper"

class RelProductWorkoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rel_product_workout = rel_product_workouts(:one)
  end

  test "should get index" do
    get rel_product_workouts_url
    assert_response :success
  end

  test "should get new" do
    get new_rel_product_workout_url
    assert_response :success
  end

  test "should create rel_product_workout" do
    assert_difference('RelProductWorkout.count') do
      post rel_product_workouts_url, params: { rel_product_workout: { product_id: @rel_product_workout.product_id, workout_id: @rel_product_workout.workout_id } }
    end

    assert_redirected_to rel_product_workout_url(RelProductWorkout.last)
  end

  test "should show rel_product_workout" do
    get rel_product_workout_url(@rel_product_workout)
    assert_response :success
  end

  test "should get edit" do
    get edit_rel_product_workout_url(@rel_product_workout)
    assert_response :success
  end

  test "should update rel_product_workout" do
    patch rel_product_workout_url(@rel_product_workout), params: { rel_product_workout: { product_id: @rel_product_workout.product_id, workout_id: @rel_product_workout.workout_id } }
    assert_redirected_to rel_product_workout_url(@rel_product_workout)
  end

  test "should destroy rel_product_workout" do
    assert_difference('RelProductWorkout.count', -1) do
      delete rel_product_workout_url(@rel_product_workout)
    end

    assert_redirected_to rel_product_workouts_url
  end
end
