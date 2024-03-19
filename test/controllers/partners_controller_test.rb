require 'test_helper'

class PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @account_partner1 = accounts(:partner1)
    @account_partner2 = accounts(:partner2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @partner1 = partners(:appy)
    @partner2 = partners(:kari)
  end

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_partner_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get partners_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as superadmin or correct account' do
    [nil, @account_client1, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get partner_path(@partner1)

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get edit_partner_path(@partner1)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Partner.count' do
        post partners_path, params:
         { partner:
            { first_name: 'test',
              last_name: 'testpartner' } }
      end
    end
  end

  test 'should redirect update when not logged in as superadmin' do
    original_first_name = @partner1.first_name
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      patch partner_path(@partner1), params:
       { partner:
          { first_name: 'Raymond',
            last_name: @partner1.last_name } }

      assert_equal original_first_name, @partner1.reload.first_name
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @account_partner2, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Partner.count' do
        delete partner_path(@partner1)
      end
    end
  end
end
