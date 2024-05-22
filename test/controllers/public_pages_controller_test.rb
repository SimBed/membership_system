require 'test_helper'

class PublicPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
  end

  test 'should get login page if not logged in' do
    get root_path

    assert_response :success
  end

  test 'should get clients index if logged in as junioradmin or more senior' do
    [@junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      # get root_path

      assert_redirected_to clients_path
    end
  end

  test 'should get clients profile if logged in as client' do
    log_in_as(@account_client)
    # get root_path

    assert_redirected_to client_book_path(@client)
  end

end
