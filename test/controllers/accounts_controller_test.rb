require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @account_partner1 = accounts(:partner1)
    @account_partner2 = accounts(:partner2)
  end

  test 'should redirect create account for client when not logged in as admin or more senior' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'client' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'client' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for partner when not logged in as senior admin' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'partner' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'partner' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for admin in all cases' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'admin' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'admin' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for junioradmin in all cases' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'junioradmin' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'junioradmin' }
      end
      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for superadmin in all cases' do
    assert_no_difference 'Account.count' do
      post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'superadmin' }
    end
    assert_redirected_to login_path
    [@account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post admin_accounts_path, params: { email: 'wannabe@example.com', client_id: ActiveRecord::FixtureSet.identify(:Wannabe), ac_type: 'superadmin' }
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

  test 'should fail attempt to destroy through app' do
    assert_no_difference 'Account.count' do
      delete admin_account_path(@account_client1)
    end
    log_in_as(@superadmin)
    assert_no_difference 'Account.count' do
      delete admin_account_path(@account_client1)
    end

  end

end
