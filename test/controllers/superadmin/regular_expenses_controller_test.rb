require 'test_helper'

class Superadmin::RegularExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @regular_expense = regular_expenses(:one)
    @superadmin = accounts(:superadmin)
    @date = Time.zone.now.beginning_of_month.to_date
  end

  test 'should get index' do
    log_in_as @superadmin
    get regular_expenses_url

    assert_response :success
  end

  test 'should get new' do
    log_in_as @superadmin
    get new_regular_expense_url

    assert_response :success
  end

  test 'should create regular_expense' do
    log_in_as @superadmin
    assert_difference('RegularExpense.count') do
      post regular_expenses_url, params: { regular_expense: { amount: @regular_expense.amount, date: @date,
                                                                         item: @regular_expense.item,
                                                                         workout_group_id: @regular_expense.workout_group_id } }
    end

    assert_redirected_to regular_expenses_url
  end

  test 'should get edit' do
    log_in_as @superadmin
    get edit_regular_expense_url(@regular_expense)

    assert_response :success
  end

  test 'should update regular_expense' do
    log_in_as @superadmin
    patch regular_expense_url(@regular_expense), params: { regular_expense: { amount: @regular_expense.amount + 50, item: @regular_expense.item,
                                                                                         workout_group_id: @regular_expense.workout_group_id } }

    assert_redirected_to regular_expenses_url
  end

  test 'should destroy regular_expense' do
    log_in_as @superadmin
    assert_difference('RegularExpense.count', -1) do
      delete regular_expense_url(@regular_expense)
    end

    assert_redirected_to regular_expenses_url
  end
end
