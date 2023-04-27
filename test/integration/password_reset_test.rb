require "test_helper"

class PasswordResetTest < ActionDispatch::IntegrationTest
  def setup
    @account = accounts(:client_for_unlimited)
    @client = @account.client
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
  end

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

end
