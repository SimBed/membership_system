require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
  end

  test "should redirect show when not logged in as superadmin" do
    [nil, @account_client1, @account_partner1, @admin, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get superadmin_settings_url
      assert_redirected_to login_path
    end
  end
end
