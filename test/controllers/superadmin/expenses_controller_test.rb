require 'test_helper'

class Superadmin::ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @account_partner2 = accounts(:partner2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @expense = expenses(:expense1)
  end

  # no show method for expenses controller

  test 'should redirect new when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get new_expense_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get expenses_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get edit_expense_path(@expense)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Expense.count' do
        post expenses_path, params:
         { expense:
            { item: 'Rope',
              amount: 2000,
              date: '2022-02-15',
              workout_group_id: @expense.workout_group_id } }
      end
    end
  end

  test 'should redirect update when not logged in as superadmin' do
    original_amount = @expense.amount
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      patch expense_path(@expense), params:
       { expense:
          { item: 'Rope',
            amount: 2000,
            date: '2022-02-15',
            workout_group_id: @expense.workout_group_id } }

      assert_equal original_amount, @expense.reload.amount
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as superadmin' do
    [nil, @account_client1, @account_partner2, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Expense.count' do
        delete expense_path(@expense)
      end
    end
  end
end
