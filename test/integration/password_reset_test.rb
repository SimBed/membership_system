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

  test 'admin resets client password' do
    assert @account.authenticate('password')
    log_in_as(@admin)
    # admin cannot specify the actual password. The new password is randomly generated on update.
    patch account_path(@account)

    refute @account.reload.authenticate('password')
  end

  # set header in request https://joshfrankel.me/blog/how-to-test-redirect-back-or-to/
  test 'client resets password with valid password' do
    log_in_as(@account)
    get client_profile_path @client
    patch account_path(@account), params: { account: { new_password: 'foobar', new_password_confirmation: 'foobar' } },
                                        headers: { referer: client_profile_url(@client) }

    refute @account.reload.authenticate('password')
    assert @account.reload.authenticate('foobar')
    assert_redirected_to client_profile_path @client
  end

  test 'client resets password with invalid password' do
    log_in_as(@account)
    patch account_path(@account), params: { account: { new_password: 'fooba', new_password_confirmation: 'fooba' } }

    assert @account.reload.authenticate('password')
    refute @account.reload.authenticate('fooba')
    assert_template 'client/data_pages/profile'
  end

  test 'client resets password with invalid password confirmation' do
    log_in_as(@account)
    patch account_path(@account), params: { account: { new_password: 'foobar', new_password_confirmation: 'barfoo' } }

    assert @account.reload.authenticate('password')
    refute @account.reload.authenticate('foobar')
    assert_template 'client/data_pages/profile'
  end

  test 'superadmin resets admin account password with valid new password (and correct admin password)' do
    log_in_as(@superadmin)
    patch account_path(@admin),
          params: { account: { new_password: 'foobar', new_password_confirmation: 'foobar', requested_by: 'superadmin_of_admin', admin_password: 'password' } }

    assert @admin.reload.authenticate('foobar')
    refute @admin.reload.authenticate('password')
  end

  test 'superadmin resets admin account password with valid new password but incorrect admin password' do
    log_in_as(@superadmin)
    patch account_path(@admin),
          params: { account: { new_password: 'foobar', new_password_confirmation: 'foobar', requested_by: 'superadmin_of_admin', admin_password: 'passwod' } }

    refute @admin.reload.authenticate('foobar')
    assert @admin.reload.authenticate('password')
  end

  test 'superadmin resets admin account password with invalid new password' do
    log_in_as(@superadmin)
    patch account_path(@admin),
          params: { account: { new_password: 'fooba', new_password_confirmation: 'fooba', requested_by: 'superadmin_of_admin', admin_password: 'password' } }

    assert @admin.reload.authenticate('password')
    refute @admin.reload.authenticate('fooba')
    assert_redirected_to accounts_path
  end

  test 'admin resets admin account password' do
    log_in_as(@admin)
    patch account_path(@admin),
          params: { account: { new_password: 'foobar', new_password_confirmation: 'foobar', requested_by: 'superadmin_of_admin', admin_password: 'password' } }

    assert @admin.reload.authenticate('password')
    refute @admin.reload.authenticate('fooba')
    assert_redirected_to login_path
  end

  # previous tests are when already logged on as admin or client. These tests are when the client has forgotten the password
  # MH 12.3.3

  test 'client password reset when password is forgotten' do
    get new_client_password_reset_path

    assert_template 'password_resets/new'
    # Invalid email
    post client_password_resets_path, params: { password_reset: { email: '' } }

    refute_empty flash
    assert_template 'password_resets/new'
    # Valid email
    post client_password_resets_path,
         params: { password_reset: { email: @account.email } }

    refute_equal @account.reset_digest, @account.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    refute_empty flash
    assert_redirected_to login_path
    # Password reset form
    account = assigns(:account)
    # Wrong email
    get edit_client_password_reset_path(account.reset_token, email: '')

    assert_redirected_to root_url
    # Inactive user
    # rubocop:disable Rails/SkipsModelValidations
    account.toggle!(:activated)
    # rubocop:enable Rails/SkipsModelValidations
    get edit_client_password_reset_path(account.reset_token, email: account.email)

    assert_redirected_to root_url
    # rubocop:disable Rails/SkipsModelValidations
    account.toggle!(:activated)
    # rubocop:enable Rails/SkipsModelValidations
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
    refute_empty flash
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

    assert_match(/expired/i, response.body)
  end
end
