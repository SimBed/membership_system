require "application_system_test_case"

class WkclassesTest < ApplicationSystemTestCase
  setup do
    @wkclass = wkclasses(:one)
  end

  test "visiting the index" do
    visit wkclasses_url
    assert_selector "h1", text: "Wkclasses"
  end

  test "creating a Wkclass" do
    visit wkclasses_url
    click_on "New Wkclass"

    fill_in "Start time", with: @wkclass.start_time
    fill_in "Workout", with: @wkclass.workout_id
    click_on "Create Wkclass"

    assert_text "Wkclass was successfully created"
    click_on "Back"
  end

  test "updating a Wkclass" do
    visit wkclasses_url
    click_on "Edit", match: :first

    fill_in "Start time", with: @wkclass.start_time
    fill_in "Workout", with: @wkclass.workout_id
    click_on "Update Wkclass"

    assert_text "Wkclass was successfully updated"
    click_on "Back"
  end

  test "destroying a Wkclass" do
    visit wkclasses_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Wkclass was successfully destroyed"
  end
end
