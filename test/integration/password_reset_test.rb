require "test_helper"

class PasswordResetTest < ActionDispatch::IntegrationTest
  def setup
    @account = accounts(:client_for_unlimited)
    @client = @account.client
    @admin = accounts(:admin)
  end

  test 'admin resets password' do
    @account.update(password: 'password', password_confirmation: 'password')
    assert @account.authenticate('password')
    log_in_as(@admin)
    patch admin_account_path(@account)
    refute @account.reload.authenticate('password')
  end

  test 'client resets password with valid password' do
    @account.update(password: 'password', password_confirmation: 'password')
    assert @account.authenticate('password')
    log_in_as(@account)
    patch admin_account_path(@account), params: { account: { new_password: 'foobar', new_password_confirmation: 'foobar' } }
    refute @account.reload.authenticate('password')
    assert @account.reload.authenticate('foobar')
  end

  test 'client resets password with invalid password' do
    @account.update(password: 'password', password_confirmation: 'password')
    assert @account.authenticate('password')
    log_in_as(@account)
    patch admin_account_path(@account), params: { account: { new_password: 'fooba', new_password_confirmation: 'fooba' } }
    assert @account.reload.authenticate('password')
    refute @account.reload.authenticate('fooba')
    assert_template 'client/clients/show'
  end

  test 'client resets password with invalid password/password confirmation combo' do
    @account.update(password: 'password', password_confirmation: 'password')
    assert @account.authenticate('password')
    log_in_as(@account)
    patch admin_account_path(@account), params: { account: { new_password: 'foobar', new_password_confirmation: 'barfoo' } }
    assert @account.reload.authenticate('password')
    refute @account.reload.authenticate('foobar')
    assert_template 'client/clients/show'
  end
end
