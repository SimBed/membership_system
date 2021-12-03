require "application_system_test_case"

class RelWorkoutGroupWorkoutsTest < ApplicationSystemTestCase
  setup do
    @rel_workout_group_workout = rel_workout_group_workouts(:one)
  end

  test "visiting the index" do
    visit rel_workout_group_workouts_url
    assert_selector "h1", text: "Rel Workout Group Workouts"
  end

  test "creating a Rel workout group workout" do
    visit rel_workout_group_workouts_url
    click_on "New Rel Workout Group Workout"

    fill_in "Workout group", with: @rel_workout_group_workout.workout_group_id
    fill_in "Workout", with: @rel_workout_group_workout.workout_id
    click_on "Create Rel workout group workout"

    assert_text "Rel workout group workout was successfully created"
    click_on "Back"
  end

  test "updating a Rel workout group workout" do
    visit rel_workout_group_workouts_url
    click_on "Edit", match: :first

    fill_in "Workout group", with: @rel_workout_group_workout.workout_group_id
    fill_in "Workout", with: @rel_workout_group_workout.workout_id
    click_on "Update Rel workout group workout"

    assert_text "Rel workout group workout was successfully updated"
    click_on "Back"
  end

  test "destroying a Rel workout group workout" do
    visit rel_workout_group_workouts_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Rel workout group workout was successfully destroyed"
  end
end
