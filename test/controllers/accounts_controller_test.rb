require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @client_without_account = clients(:client_without_account)
    @partner_without_account = partners(:bibi)
    @instructor_account = accounts(:head_coach)
  end

  # the accounts controller only has a create method.
  # it is not possible to update/destroy etc.. through the application

  test 'should redirect create account for client when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post accounts_path, params: { email: @client_without_account.email,
                                            client_id: @client_without_account.id,
                                            ac_type: 'client' }
      end

      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for partner when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post accounts_path, params: { email: @partner_without_account.email,
                                            partner_id: @partner_without_account.id,
                                            ac_type: 'partner' }
      end

      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for admin in all cases' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post accounts_path, params: { email: @client_without_account.email,
                                            client_id: @client_without_account.id,
                                            ac_type: 'admin' }
      end

      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for junioradmin in all cases' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post accounts_path, params: { email: @client_without_account.email,
                                            client_id: @client_without_account.id,
                                            ac_type: 'junioradmin' }
      end

      assert_redirected_to login_path
    end
  end

  test 'should redirect create account for superadmin in all cases' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        post accounts_path, params: { email: @client_without_account.email,
                                            client_id: @client_without_account.id,
                                            ac_type: 'superadmin' }
      end

      assert_redirected_to login_path
    end
  end

  test 'should redirect create account if no associated client/partner/instructor' do
    log_in_as(@superadmin)
    assert_no_difference 'Account.count' do
      post accounts_path, params:
       { email: 'wannabe@example.com',
         ac_type: 'client' }
    end

    assert_redirected_to login_path
  end

  test 'should redirect destroy account for admin when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        delete account_path(@admin)
      end

      assert_redirected_to login_path
    end
  end  

  test 'should redirect destroy account for instructor when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Account.count' do
        delete account_path(@instructor_account)
      end

      assert_redirected_to login_path
    end
  end  
end
