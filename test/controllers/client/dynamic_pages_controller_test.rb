require "test_helper"

class Client::DynamicPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @junioradmin = accounts(:junioradmin)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
  end

  test 'should redirect book when not logged in as account of the client' do
    [nil, @account_client2, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      get client_book_path(@account_client1.client)

      assert_redirected_to login_path
    end
  end
end
