require 'test_helper'

class PublicPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @account_partner = accounts(:partner1)
    @partner = @account_partner.partner
  end

  test 'should get login page if not logged in' do
    get root_path

    assert_response :success
  end

  test 'should get clients index if logged in as junioradmin or more senior' do
    [@junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      # get root_path

      assert_redirected_to admin_clients_path
    end
  end

  test 'should get clients profile if logged in as client' do
    log_in_as(@account_client)
    # get root_path

    assert_redirected_to client_book_path(@client)
  end

  test 'should get partners profile if logged in as partner' do
    log_in_as(@account_partner)
    # get root_path

    assert_redirected_to admin_partner_path(@partner)
  end

  # test "should get shop" do
  #   get '/shop'
  #   assert_response :success
  # end
end
