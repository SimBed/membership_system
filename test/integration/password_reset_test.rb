require 'test_helper'

class PasswordResetTest < ActionDispatch::IntegrationTest
  def setup
    @account = accounts(:client_for_unlimited)
    @client = @account.client
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    ActionMailer::Base.deliveries.clear
  end

  # first batch of tests are when already logged on as admin or client. Final test is when the client has forgotten the password

  test 'admin resets password' do
    assert @account.authenticate('password')
    log_in_as(@admin)
    # admin cannot specify the actual password. The new password is randoml;y generated on update.
    patch admin_account_path(@account)

    refute @account.reload.authenticate('password')
  end

  test 'client resets password with valid password' do
    log_in_as(@account)
    patch admin_account_path(@account), params: { account: { new_password: 'foobar', new_password_confirmation: 'foobar' } }

    refute @account.reload.authenticate('password')
    assert @account.reload.authenticate('foobar')
  end

  test 'client resets password with invalid password' do
    log_in_as(@account)
    patch admin_account_path(@account), params: { account: { new_password: 'fooba', new_password_confirmation: 'fooba' } }

    assert @account.reload.authenticate('password')
    refute @account.reload.authenticate('fooba')
    assert_template 'client/clients/show'
  end

  test 'client resets password with invalid password/password confirmation combo' do
    log_in_as(@account)
    patch admin_account_path(@account), params: { account: { new_password: 'foobar', new_password_confirmation: 'barfoo' } }

    assert @account.reload.authenticate('password')
    refute @account.reload.authenticate('foobar')
    assert_template 'client/clients/show'
  end

  test 'superadmin resets admin account password with valid password' do
    log_in_as(@superadmin)
    patch admin_account_path(@admin), params: { account: { new_password: 'foobar', new_password_confirmation: 'foobar', requested_by: 'superadmin_of_admin' } }

    assert @admin.reload.authenticate('foobar')
    refute @admin.reload.authenticate('password')
  end

  test 'superadmin resets admin account password with invalid password' do
    log_in_as(@superadmin)
    patch admin_account_path(@admin), params: { account: { new_password: 'fooba', new_password_confirmation: 'fooba', requested_by: 'superadmin_of_admin' } }

    assert @admin.reload.authenticate('password')
    refute @admin.reload.authenticate('fooba')
    assert_redirected_to admin_accounts_path
  end

  # previous tests are when already logged on as admin or client. These tests are when the client has forgotten the password
  # MH 12.3.3

  test 'password reset when password is forgotten' do
    get new_client_password_reset_path

    assert_template 'password_resets/new'
    # Invalid email
    post client_password_resets_path, params: { password_reset: { email: '' } }

    refute flash.empty?
    assert_template 'password_resets/new'
    # Valid email
    post client_password_resets_path,
         params: { password_reset: { email: @account.email } }

    refute_equal @account.reset_digest, @account.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    refute flash.empty?
    assert_redirected_to login_path
    # Password reset form
    account = assigns(:account)
    # Wrong email
    get edit_client_password_reset_path(account.reset_token, email: '')

    assert_redirected_to root_url
    # Inactive user
    account.toggle!(:activated)
    get edit_client_password_reset_path(account.reset_token, email: account.email)

    assert_redirected_to root_url
    account.toggle!(:activated)
    # Right email, wrong token
    get edit_client_password_reset_path('wrong token', email: account.email)

    assert_redirected_to root_url
    # Right email, right token
    get edit_client_password_reset_path(account.reset_token, email: account.email)

    assert_template 'password_resets/edit'
    assert_select 'input[name=email][type=hidden][value=?]', account.email
    # Invalid password & confirmation
    patch client_password_reset_path(account.reset_token),
          params: { email: account.email,
                    account: { password: 'foobaz',
                               password_confirmation: 'barquux' } }

    assert_select 'div#error_explanation'
    # Empty password
    patch client_password_reset_path(account.reset_token),
          params: { email: account.email,
                    account: { password: '',
                               password_confirmation: '' } }

    assert_select 'div#error_explanation'
    # Valid password & confirmation
    patch client_password_reset_path(account.reset_token),
          params: { email: account.email,
                    account: { password: 'foobaz',
                               password_confirmation: 'foobaz' } }

    assert is_logged_in?
    refute flash.empty?
    assert_redirected_to client_book_path(account.client)
    assert_nil account.reload.reset_digest
  end

  test 'expired token' do
    get new_client_password_reset_path
    post client_password_resets_path,
         params: { password_reset: { email: @account.email } }
    @account = assigns(:account)
    @account.update_column(:reset_sent_at, 3.hours.ago)
    patch client_password_reset_path(@account.reset_token),
          params: { email: @account.email,
                    account: { password: 'foobar',
                               password_confirmation: 'foobar' } }

    assert_response :redirect
    follow_redirect!

    assert_match /expired/i, response.body
  end
end
