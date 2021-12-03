require "application_system_test_case"

class WorkoutGroupsTest < ApplicationSystemTestCase
  setup do
    @workout_group = workout_groups(:one)
  end

  test "visiting the index" do
    visit workout_groups_url
    assert_selector "h1", text: "Workout Groups"
  end

  test "creating a Workout group" do
    visit workout_groups_url
    click_on "New Workout Group"

    fill_in "Name", with: @workout_group.name
    click_on "Create Workout group"

    assert_text "Workout group was successfully created"
    click_on "Back"
  end

  test "updating a Workout group" do
    visit workout_groups_url
    click_on "Edit", match: :first

    fill_in "Name", with: @workout_group.name
    click_on "Update Workout group"

    assert_text "Workout group was successfully updated"
    click_on "Back"
  end

  test "destroying a Workout group" do
    visit workout_groups_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Workout group was successfully destroyed"
  end
end
