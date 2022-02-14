require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client1 = accounts(:client1)
    @client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @partner1 = accounts(:partner1)
    @partner2 = accounts(:partner2)
  end

  test "should redirect index when not logged in as junioradmin or more senior" do
    get admin_clients_url
    assert_redirected_to login_path
    log_in_as(@client1)
    get admin_clients_url
    assert_redirected_to login_path
    log_in_as(@partner1)
    get admin_clients_url
    assert_redirected_to login_path
  end

  test "should redirect new when not logged in as junioradmin or more senior" do
    get new_admin_client_url
    assert_redirected_to login_path
    log_in_as(@client1)
    get new_admin_client_url
    assert_redirected_to login_path
    log_in_as(@partner1)
    get new_admin_client_url
    assert_redirected_to login_path
  end

  test 'should redirect show when not logged in as admin or more senior or correct account' do
    get admin_client_path(@client2.clients.first)
    assert_redirected_to root_url
    log_in_as(@client1)
    get admin_client_path(@client2.clients.first)
    assert_redirected_to root_url
    log_in_as(@partner1)
    get admin_client_path(@client2.clients.first)
    assert_redirected_to root_url
    log_in_as(@junioradmin)
    get admin_client_path(@client2.clients.first)
    assert_redirected_to root_url
  end

  test 'should redirect edit when not logged in as junioradmin or more senior' do
    get edit_admin_client_path(@client2.clients.first)
    assert_redirected_to login_path
    log_in_as(@client1)
    get edit_admin_client_path(@client2.clients.first)
    assert_redirected_to login_path
    log_in_as(@partner1)
    get edit_admin_client_path(@client2.clients.first)
    assert_redirected_to login_path
  end

  test 'should redirect create when not logged in as junior admin or more senior' do
    assert_no_difference 'Client.count' do
      post admin_clients_path, params: { client: { first_name: 'test', last_name: 'tester', email: 'example@example.com' } }
    end
    assert_redirected_to login_path
    log_in_as(@client1)
    assert_no_difference 'Client.count' do
      post admin_clients_path, params: { client: { first_name: 'test', last_name: 'tester', email: 'example@example.com' } }
    end
    assert_redirected_to login_path
    log_in_as(@partner1)
    assert_no_difference 'Client.count' do
      post admin_clients_path, params: { client: { first_name: 'test', last_name: 'tester', email: 'example@example.com' } }
    end
    assert_redirected_to login_path
  end

  test 'should redirect update when not logged in as junior admin or more senior' do
    patch admin_client_path(@client2.clients.first), params: { client: { instagram: 'test' } }
    assert_redirected_to login_path
    log_in_as(@client1)
    patch admin_client_path(@client2.clients.first), params: { client: { instagram: 'test' } }
    assert_redirected_to login_path
    log_in_as(@partner1)
    patch admin_client_path(@client2.clients.first), params: { client: { instagram: 'test' } }
    assert_redirected_to login_path
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    assert_no_difference 'Client.count' do
      delete admin_client_path(@client1.clients.first)
    end
    assert_redirected_to login_path
    log_in_as(@client1)
    assert_no_difference 'Client.count' do
      delete admin_client_path(@client1.clients.first)
    end
    assert_redirected_to login_path
    log_in_as(@partner1)
    assert_no_difference 'Client.count' do
      delete admin_client_path(@client1.clients.first)
    end
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    assert_no_difference 'Client.count' do
      delete admin_client_path(@client1.clients.first)
    end
    assert_redirected_to login_path
  end
end
