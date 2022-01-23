require "application_system_test_case"

class InstructorSalariesTest < ApplicationSystemTestCase
  setup do
    @instructor_salary = instructor_salaries(:one)
  end

  test "visiting the index" do
    visit instructor_salaries_url
    assert_selector "h1", text: "Instructor Salaries"
  end

  test "creating a Instructor salary" do
    visit instructor_salaries_url
    click_on "New Instructor Salary"

    fill_in "Date from", with: @instructor_salary.date_from
    fill_in "Instructor", with: @instructor_salary.instructor_id
    fill_in "Salary", with: @instructor_salary.salary
    click_on "Create Instructor salary"

    assert_text "Instructor salary was successfully created"
    click_on "Back"
  end

  test "updating a Instructor salary" do
    visit instructor_salaries_url
    click_on "Edit", match: :first

    fill_in "Date from", with: @instructor_salary.date_from
    fill_in "Instructor", with: @instructor_salary.instructor_id
    fill_in "Salary", with: @instructor_salary.salary
    click_on "Update Instructor salary"

    assert_text "Instructor salary was successfully updated"
    click_on "Back"
  end

  test "destroying a Instructor salary" do
    visit instructor_salaries_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Instructor salary was successfully destroyed"
  end
end
