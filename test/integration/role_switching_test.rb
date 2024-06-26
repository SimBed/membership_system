require 'test_helper'
require 'sessions_helper'

class RoleSwitchingTest < ActionDispatch::IntegrationTest
  include SessionsHelper
  setup do
    @superadmin = accounts(:superadmin)
    @account_client = accounts(:client_for_unlimited)
    @role_superadmin = roles(:superadmin)
    @role_client = roles(:client)
  end

  test 'payments index accessible under superadmin role but not under admin role; clients index accessible under superadmin role and admin role but not under client role' do
    log_in_as(@superadmin)
    get clients_path

    assert_template 'admin/clients/index'
    assert_select 'a[href=?]', payments_path
    switch_role_to('admin')
    get clients_path

    assert_template 'admin/clients/index'
    assert_select 'a[href=?]', payments_path, count: 0
    switch_role_to('client')

    assert_select 'a[href=?]', clients_path, count: 0
    get clients_path

    assert_redirected_to login_path
  end

  test 'client without admin role attempts to switch role to admin' do
    log_in_as(@account_client)
    switch_role_to('admin')

    assert_equal 'unauthorised role', flash[:warning]
    assert_redirected_to login_path
  end

  test 'view priority' do
    log_in_as(@superadmin)

    assert_equal 'superadmin', current_role
    log_out
    @role_superadmin.update(view_priority: 6)
    @role_client.update(view_priority: 1)
    log_in_as(@account_client)

    assert_equal 'client', current_role
  end
end
