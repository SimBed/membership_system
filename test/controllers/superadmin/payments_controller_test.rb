require "test_helper"

class Superadmin::PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
  end

  test 'should redirect index when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get superadmin_payments_path

      assert_redirected_to login_path
    end
  end
end
