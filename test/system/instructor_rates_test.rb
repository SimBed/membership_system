require "application_system_test_case"

class InstructorRatesTest < ApplicationSystemTestCase
  setup do
    @instructor_rate = instructor_rates(:one)
  end

  test "visiting the index" do
    visit instructor_rates_url
    assert_selector "h1", text: "Instructor Rates"
  end

  test "creating a Instructor rate" do
    visit instructor_rates_url
    click_on "New Instructor Rate"

    fill_in "Date from", with: @instructor_rate.date_from
    fill_in "Instructor", with: @instructor_rate.instructor_id
    fill_in "Rate", with: @instructor_rate.rate
    click_on "Create Instructor rate"

    assert_text "Instructor rate was successfully created"
    click_on "Back"
  end

  test "updating a Instructor rate" do
    visit instructor_rates_url
    click_on "Edit", match: :first

    fill_in "Date from", with: @instructor_rate.date_from
    fill_in "Instructor", with: @instructor_rate.instructor_id
    fill_in "Rate", with: @instructor_rate.rate
    click_on "Update Instructor rate"

    assert_text "Instructor rate was successfully updated"
    click_on "Back"
  end

  test "destroying a Instructor rate" do
    visit instructor_rates_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Instructor rate was successfully destroyed"
  end
end
