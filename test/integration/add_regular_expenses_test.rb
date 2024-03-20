require 'test_helper'

class AddRegularExpensesTest < ActionDispatch::IntegrationTest
  def setup
    @superadmin = accounts(:superadmin)
    log_in_as @superadmin
    travel_to(Date.parse('Jan 1 2023'))
    @regular_expense = regular_expenses(:one)
  end

  test 'add new expenses from regular expenses' do
    assert_equal 3, RegularExpense.all.size

    assert_difference 'Expense.all.size', 3 do
      post regular_expenses_add_path(date:'Jan 1 2023')
      # post "/regular_expenses/add?date='Jan 1 2023'"
    end

    # they wil be duplicates if added again so rejected
    assert_difference 'Expense.all.size', 0 do
      post regular_expenses_add_path(date:'Jan 1 2023')
    end
  end

  test 'add duplicate expenses' do
    post regular_expenses_add_path(date:'Jan 1 2023')
    assert_difference 'RegularExpense.all.size', 1 do
      RegularExpense.create(
        item: 'roti',
        amount: 25,
        workout_group_id: @regular_expense.workout_group_id
      )
    end

    # only the new (non-duplicate) regular expenses should be responsible for a new expense)
    assert_difference 'Expense.all.size', 1 do
      post regular_expenses_add_path(date:'Jan 1 2023')
    end
  end
end
