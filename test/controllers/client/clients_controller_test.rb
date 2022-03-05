require "test_helper"
class Client::ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client1 = accounts(:client1)
    @client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @partner1 = accounts(:partner1)
    @partner2 = accounts(:partner2)
  end

  test 'should redirect show when not logged in as account of the client' do
    get client_client_path(@client1.clients.first)
    assert_redirected_to login_path
    [@client2, @partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      get client_client_path(@client1.clients.first)
      assert_redirected_to login_path
    end
  end
end
