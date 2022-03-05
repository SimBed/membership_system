require "test_helper"
class ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client1 = accounts(:client1)
    @client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @partner1 = accounts(:partner1)
    @partner2 = accounts(:partner2)
  end

  test "should redirect index when not logged in as senioradmin" do
    get superadmin_expenses_url
    assert_redirected_to login_path
    log_in_as(@client1)
    get superadmin_expenses_url
    assert_redirected_to login_path
    log_in_as(@partner1)
    get superadmin_expenses_url
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    get superadmin_expenses_url
    assert_redirected_to login_path
    log_in_as(@admin)
    get superadmin_expenses_url
    assert_redirected_to login_path
  end
end
