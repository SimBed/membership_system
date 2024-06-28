require 'test_helper'

class AccountLoginTest < ActionDispatch::IntegrationTest
  def setup
    @admin = accounts(:admin)
    @client_account = accounts(:client_for_unlimited)
  end

  test 'login with invalid information' do
    get login_path

    assert_template 'sessions/new'
    post login_path, params: { session: { email: '', password: '' } }

    assert_template 'sessions/new'
    refute_empty flash
    get root_path

    assert_empty flash
  end

  test 'admin login with valid information followed by logout' do
    get login_path
    post login_path, params: { session: { email: @admin.email,
                                          password: 'password' } }

    assert is_logged_in?
    assert_redirected_to clients_path
    follow_redirect!

    assert_template 'admin/clients/index'
    assert_select 'a[href=?]', login_path, count: 0
    assert_select 'a[href=?]', logout_path
    delete logout_path

    refute is_logged_in?
    assert_redirected_to root_path
    # Simulate a user clicking logout in a second window.
    delete logout_path
    follow_redirect!

    assert_select 'a[href=?]', login_path
    assert_select 'a[href=?]', logout_path, count: 0
  end

  test 'admin login with remembering (enforced)' do
    assert_difference 'Login.where(by_cookie: false).count', 1 do
      log_in_as(@admin)
    end
    refute_empty cookies[:remember_token]
    delete logout_path

    assert_empty cookies[:remember_token]
    assert_nil @admin.remember_digest
    assert_no_difference 'Login.count' do
      get clients_path
    end
  end

  test 'admin login with remembering after browser closed' do
    log_in_as(@admin)
    # Simulate browser being closed, while retaining remembering cookies (that logout would destroy)
    # want to set session[:account_id] to nil but sessions can't be directly amended in integration tests, but can be via a http request passing through a controller
    # https://github.com/rails/rails/issues/18222
    # the rationale is that integration tests are meant to simulate user behaviour (and users can't directly write to sessions) though this seems to miss that users can alter sessions by closing browsers...
    get close_the_browser_path
    assert_difference 'Login.where(by_cookie: true).count', 1 do
      get clients_path
    end
    assert_template 'admin/clients/index'
  end

  # repeat for client
  test 'client login with valid information followed by logout' do
    get login_path
    post login_path, params: { session: { email: @client_account.email,
                                          password: 'password' } }

    assert is_logged_in?
    assert_redirected_to client_bookings_path(@client_account.client)
    follow_redirect!

    assert_template 'client/bookings/index'
    assert_select 'a[href=?]', login_path, count: 0
    assert_select 'a[href=?]', logout_path
    delete logout_path

    refute is_logged_in?
    assert_redirected_to root_path
    # Simulate a user clicking logout in a second window.
    delete logout_path
    follow_redirect!

    assert_select 'a[href=?]', login_path
    assert_select 'a[href=?]', logout_path, count: 0
  end

  test 'client login with remembering (enforced)' do
    assert_difference 'Login.where(by_cookie: false).count', 1 do
      log_in_as(@client_account)
    end
    refute_empty cookies[:remember_token]
    delete logout_path

    assert_empty cookies[:remember_token]
    assert_nil @admin.remember_digest
    assert_no_difference 'Login.count' do
      get client_bookings_path(@client_account.client)
    end
  end

  test 'client login with remembering after browser closed' do
    log_in_as(@client_account)
    get close_the_browser_path
    assert_difference 'Login.where(by_cookie: true).count', 1 do
      get client_bookings_path(@client_account.client)
    end
    assert_template 'client/bookings/index'
  end
end
