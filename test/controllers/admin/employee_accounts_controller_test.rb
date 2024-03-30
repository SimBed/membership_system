require "test_helper"

class Admin::EmployeeAccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @superadmin = accounts(:superadmin)
  end

  test "should get index" do
    log_in_as(@superadmin)
    get employee_accounts_path
    assert_response :success
  end
end
