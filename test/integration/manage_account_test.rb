require "test_helper"

class ManageAccountTest < ActionDispatch::IntegrationTest
  setup do
    @superadmin = accounts(:superadmin)
    @admin = accounts(:admin) # admin & junioradmin
    @junioradmin = accounts(:junioradmin) # junioradmin only
    @admin_instructor = accounts(:head_coach) # instructor & admin
  end

  test 'delete admin account with just 1 role' do
    log_in_as(@superadmin)
    assert_difference -> { Account.count } => -1, -> { Assignment.count } => -1 do
      delete employee_account_path(@junioradmin)
    end
  end

  test 'delete admin account with multiple roles' do
    log_in_as(@superadmin)
    assert_difference -> { Account.count } => -1, -> { Assignment.count } => -2 do
      delete employee_account_path(@admin)
    end
  end

  test 'delete instructor account with admin role' do
    log_in_as(@superadmin)
    assert_difference -> { Account.count } => -1, -> { Assignment.count } => -2 do
      delete employee_account_path(@admin_instructor)
    end
  end
end
