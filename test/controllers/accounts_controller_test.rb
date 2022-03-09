require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @client_with_no_account = clients(:wannabe)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
  end

  test 'should redirect create account for client when not logged in as admin or more senior' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com',
                                          client_id: @client_with_no_account.id,
                                          ac_type: 'client' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com',
                                            client_id: @client_with_no_account.id,
                                            ac_type: 'client' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for partner when not logged in as superadmin' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com',
                                          client_id: @client_with_no_account.id,
                                          ac_type: 'partner' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com',
                                            client_id: @client_with_no_account.id,
                                            ac_type: 'partner' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for admin in all cases' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com',
                                          client_id: @client_with_no_account.id,
                                          ac_type: 'admin' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com',
                                            client_id: @client_with_no_account.id,
                                            ac_type: 'admin' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for junioradmin in all cases' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com',
                                          client_id: @client_with_no_account.id,
                                          ac_type: 'junioradmin' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com',
                                            client_id: @client_with_no_account.id,
                                            ac_type: 'junioradmin' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for superadmin in all cases' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com',
                                          client_id: @client_with_no_account.id,
                                          ac_type: 'superadmin' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com',
                                            client_id: @client_with_no_account.id,
                                            ac_type: 'superadmin' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account if no associated client/partner' do
    log_in_as(@superadmin)
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com', ac_type: 'client' }
    end
    assert_redirected_to login_path
  end

  test 'attempt to destroy through app should fail' do
    assert_no_difference 'Account.count' do
      delete admin_account_path(@account_client1)
    end
    log_in_as(@superadmin)
    assert_no_difference 'Account.count' do
      delete admin_account_path(@account_client1)
    end
  end

  test 'attempt to update through app should fail' do
    patch admin_account_path(@account_client1.id), params: {ac_type: 'admin'}
    refute_equal @account_client1.ac_type, 'admin'
    log_in_as(@superadmin)
    patch admin_account_path(@account_client1.id), params: {ac_type: 'admin'}
    assert_equal @account_client1.ac_type, 'client'
  end
end
