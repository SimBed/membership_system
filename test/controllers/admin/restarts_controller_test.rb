require "test_helper"

class Admin::RestartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client3)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
  end

  test 'should redirect index when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get admin_restarts_path

      assert_redirected_to login_path
    end
  end

end
