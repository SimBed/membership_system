require "test_helper"

class Admin::RestartsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client3)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
  end

  test 'should redirect index when not logged in as junioradmin or more senior' do
    [nil, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get restarts_path

      assert_redirected_to login_path
    end
  end

end
