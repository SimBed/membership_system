require 'test_helper'

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @client = clients(:client_ekta_unlimited)
  end

  test 'should redirect new when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get new_client_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get clients_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get client_path(@client)

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get edit_client_path(@client)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Client.count' do
        post clients_path, params:
          { client:
             { first_name: 'test',
               last_name: 'tester',
               email: 'example@example.com' } }
      end
    end
  end

  test 'should redirect update when not logged in as junioradmin or more senior' do
    original_email = @client.email
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      patch client_path(@client), params:
        { client:
           { first_name: @client.first_name,
             last_name: @client.last_name,
             email: 'alt@example.com' } }

      assert_equal original_email, @client.reload.email
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Client.count' do
        delete client_path(@client)
      end
    end
  end
end
