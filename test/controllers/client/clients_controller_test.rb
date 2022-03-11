require 'test_helper'

class Client::ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
  end

  # only show method for client_client controller

  test 'should redirect show when not logged in as account of the client' do
    [nil, @account_client2, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      get client_client_path(@account_client1.clients.first)
      assert_redirected_to login_path
    end
  end
end
