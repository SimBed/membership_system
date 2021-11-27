require "application_system_test_case"

class RelProductWorkoutsTest < ApplicationSystemTestCase
  setup do
    @rel_product_workout = rel_product_workouts(:one)
  end

  test "visiting the index" do
    visit rel_product_workouts_url
    assert_selector "h1", text: "Rel Product Workouts"
  end

  test "creating a Rel product workout" do
    visit rel_product_workouts_url
    click_on "New Rel Product Workout"

    fill_in "Product", with: @rel_product_workout.product_id
    fill_in "Workout", with: @rel_product_workout.workout_id
    click_on "Create Rel product workout"

    assert_text "Rel product workout was successfully created"
    click_on "Back"
  end

  test "updating a Rel product workout" do
    visit rel_product_workouts_url
    click_on "Edit", match: :first

    fill_in "Product", with: @rel_product_workout.product_id
    fill_in "Workout", with: @rel_product_workout.workout_id
    click_on "Update Rel product workout"

    assert_text "Rel product workout was successfully updated"
    click_on "Back"
  end

  test "destroying a Rel product workout" do
    visit rel_product_workouts_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Rel product workout was successfully destroyed"
  end
end
