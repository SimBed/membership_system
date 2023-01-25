require "application_system_test_case"

class Superadmin::RegularExpensesTest < ApplicationSystemTestCase
  setup do
    @superadmin_regular_expense = superadmin_regular_expenses(:one)
  end

  test "visiting the index" do
    visit superadmin_regular_expenses_url
    assert_selector "h1", text: "Superadmin/Regular Expenses"
  end

  test "creating a Regular expense" do
    visit superadmin_regular_expenses_url
    click_on "New Superadmin/Regular Expense"

    fill_in "Amount", with: @superadmin_regular_expense.amount
    fill_in "Date", with: @superadmin_regular_expense.date
    fill_in "Item", with: @superadmin_regular_expense.item
    fill_in "Workout group", with: @superadmin_regular_expense.workout_group_id
    click_on "Create Regular expense"

    assert_text "Regular expense was successfully created"
    click_on "Back"
  end

  test "updating a Regular expense" do
    visit superadmin_regular_expenses_url
    click_on "Edit", match: :first

    fill_in "Amount", with: @superadmin_regular_expense.amount
    fill_in "Date", with: @superadmin_regular_expense.date
    fill_in "Item", with: @superadmin_regular_expense.item
    fill_in "Workout group", with: @superadmin_regular_expense.workout_group_id
    click_on "Update Regular expense"

    assert_text "Regular expense was successfully updated"
    click_on "Back"
  end

  test "destroying a Regular expense" do
    visit superadmin_regular_expenses_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Regular expense was successfully destroyed"
  end
end
