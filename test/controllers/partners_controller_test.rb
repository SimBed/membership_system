require "test_helper"

class PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client1 = accounts(:client1)
    @client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @partner1 = accounts(:partner1)
    @partner2 = accounts(:partner2)
  end

  test "should redirect index when not logged in as admin or more senior" do
    get admin_partners_url
    assert_redirected_to login_path
    log_in_as(@client1)
    get admin_partners_url
    assert_redirected_to login_path
    log_in_as(@partner1)
    get admin_partners_url
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    get admin_partners_url
    assert_redirected_to login_path
  end

  test "should redirect new when not logged in as admin or more senior" do
    get new_admin_partner_url
    assert_redirected_to login_path
    log_in_as(@client1)
    get new_admin_partner_url
    assert_redirected_to login_path
    log_in_as(@partner1)
    get new_admin_partner_url
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    get new_admin_partner_url
    assert_redirected_to login_path
  end

  test 'should redirect show when not logged in as superadmin or correct account' do
    get admin_partner_path(@partner2.partners.first)
    assert_redirected_to root_url
    log_in_as(@client1)
    get admin_partner_path(@partner2.partners.first)
    assert_redirected_to root_url
    log_in_as(@partner1)
    get admin_partner_path(@partner2.partners.first)
    assert_redirected_to root_url
    log_in_as(@junioradmin)
    get admin_partner_path(@partner2.partners.first)
    assert_redirected_to root_url
    log_in_as(@admin)
    get admin_partner_path(@partner2.partners.first)
    assert_redirected_to root_url
  end

  test 'should redirect edit when not logged in as superadmin' do
    get edit_admin_partner_path(@partner2.partners.first)
    assert_redirected_to login_path
    log_in_as(@client1)
    get edit_admin_partner_path(@partner2.partners.first)
    assert_redirected_to login_path
    log_in_as(@partner2)
    get edit_admin_partner_path(@partner2.partners.first)
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    get admin_partner_path(@partner2.partners.first)
    assert_redirected_to root_url
    log_in_as(@admin)
    get admin_partner_path(@partner2.partners.first)
    assert_redirected_to root_url
  end

  test 'should redirect create when not logged in as admin or more senior' do
    assert_no_difference 'Partner.count' do
      post admin_partners_path, params: { partner: { first_name: 'test', last_name: 'tester' } }
    end
    assert_redirected_to login_path
    log_in_as(@client1)
    assert_no_difference 'Partner.count' do
      post admin_partners_path, params: { partner: { first_name: 'test', last_name: 'tester' } }
    end
    assert_redirected_to login_path
    log_in_as(@partner1)
    assert_no_difference 'Partner.count' do
      post admin_partners_path, params: { partner: { first_name: 'test', last_name: 'tester' } }
    end
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    assert_no_difference 'Partner.count' do
      post admin_partners_path, params: { partner: { first_name: 'test', last_name: 'tester' } }
    end
    assert_redirected_to login_path
  end

  test 'should redirect update when not logged in as superadmin' do
    patch admin_partner_path(@partner2.partners.first), params: { partner: { first_name: 'bob' } }
    assert_redirected_to login_path
    log_in_as(@client1)
    patch admin_partner_path(@partner2.partners.first), params: { partner: { first_name: 'bob' } }
    assert_redirected_to login_path
    log_in_as(@partner2)
    patch admin_partner_path(@partner2.partners.first), params: { partner: { first_name: 'bob' } }
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    patch admin_partner_path(@partner2.partners.first), params: { partner: { first_name: 'bob' } }
    assert_redirected_to login_path
    log_in_as(@admin)
    patch admin_partner_path(@partner2.partners.first), params: { partner: { first_name: 'bob' } }
    assert_redirected_to root_url
  end

  test 'should redirect destroy when not logged in as admin' do
    assert_no_difference 'Partner.count' do
      delete admin_partner_path(@partner2.partners.first)
    end
    assert_redirected_to login_path
    log_in_as(@client1)
    assert_no_difference 'Partner.count' do
      delete admin_partner_path(@partner2.partners.first)
    end
    assert_redirected_to login_path
    log_in_as(@partner2)
    assert_no_difference 'Partner.count' do
      delete admin_partner_path(@partner2.partners.first)
    end
    assert_redirected_to login_path
    log_in_as(@junioradmin)
    assert_no_difference 'Partner.count' do
      delete admin_partner_path(@partner2.partners.first)
    end
    assert_redirected_to login_path
    log_in_as(@admin)
    assert_no_difference 'Partner.count' do
      delete admin_partner_path(@partner2.partners.first)
    end
    assert_redirected_to root_url
  end
end
