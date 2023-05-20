require 'test_helper'

class SiteLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @junioradmin = accounts(:junioradmin)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @account_partner = accounts(:partner1)
    @partner = @account_partner.partner
    @account_client = accounts(:client1)
    @client = @account_client.client
  end

  test 'layout links when logged-in as superadmin' do
    log_in_as(@superadmin)
    follow_redirect!
    assert_template 'admin/clients/index'
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', admin_clients_path
    assert_select 'a[href=?]', admin_purchases_path
    assert_select 'a[href=?]', admin_wkclasses_path
    assert_select 'a[href=?]', public_timetable_path
    assert_select 'a[href=?]', admin_fitternities_path, count: 0
    assert_select 'a[href=?]', admin_products_path
    assert_select 'a[href=?]', admin_instructors_path
    assert_select 'a[href=?]', admin_partners_path
    assert_select 'a[href=?]', admin_timetables_path
    assert_select 'a[href=?]', admin_workouts_path
    assert_select 'a[href=?]', admin_workout_groups_path
    assert_select 'a[href=?]', admin_accounts_path
    assert_select 'a[href=?]', superadmin_discounts_path
    assert_select 'a[href=?]', superadmin_discount_reasons_path
    assert_select 'a[href=?]', superadmin_expenses_path
    assert_select 'a[href=?]', superadmin_regular_expenses_path
    assert_select 'a[href=?]', superadmin_instructor_rates_path
    assert_select 'a[href=?]', superadmin_orders_path
    assert_select 'a[href=?]', superadmin_settings_path
    assert_select 'div.dropdown-item', "*superadmin"    
    assert_select 'a[href=?]', "/switch_account_role?role=superadmin", count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=admin"
    assert_select 'a[href=?]', "/switch_account_role?role=junioradmin"
    assert_select 'a[href=?]', "/switch_account_role?role=instructor"
    assert_select 'a[href=?]', "/switch_account_role?role=client"
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', '/terms&conditions'
    assert_select 'a[href=?]', '/charges&deductions'
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', 'https://www.instagram.com/thespace.juhu/'
    assert_select 'a[href=?]', 'https://www.facebook.com/TheSpace.Mumbai/timeline'
    assert_select 'a[href=?]', 'https://wa.me/919619348427'
  end

  test 'layout links when logged-in as admin' do
    log_in_as(@admin)
    follow_redirect!
    assert_template 'admin/clients/index'
    # puts response.body[0,5000]
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', admin_clients_path
    assert_select 'a[href=?]', admin_purchases_path
    assert_select 'a[href=?]', admin_wkclasses_path
    assert_select 'a[href=?]', public_timetable_path
    assert_select 'a[href=?]', admin_fitternities_path, count: 0
    assert_select 'a[href=?]', admin_products_path
    assert_select 'a[href=?]', admin_instructors_path
    assert_select 'a[href=?]', admin_partners_path
    assert_select 'a[href=?]', admin_timetables_path    
    assert_select 'a[href=?]', admin_workouts_path
    assert_select 'a[href=?]', admin_workout_groups_path
    assert_select 'a[href=?]', admin_accounts_path, count: 0
    assert_select 'a[href=?]', superadmin_discounts_path, count: 0
    assert_select 'a[href=?]', superadmin_discount_reasons_path, count: 0
    assert_select 'a[href=?]', superadmin_expenses_path, count: 0
    assert_select 'a[href=?]', superadmin_regular_expenses_path, count: 0
    assert_select 'a[href=?]', superadmin_instructor_rates_path, count: 0
    assert_select 'a[href=?]', superadmin_orders_path, count: 0
    assert_select 'a[href=?]', superadmin_settings_path, count: 0  
    assert_select 'div.dropdown-item', "*admin"
    assert_select 'a[href=?]', "/switch_account_role?role=superadmin", count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=admin", count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=junioradmin"
    assert_select 'a[href=?]', "/switch_account_role?role=instructor", count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=client", count: 0
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', '/terms&conditions'
    assert_select 'a[href=?]', '/charges&deductions'
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', 'https://www.instagram.com/thespace.juhu/'
    assert_select 'a[href=?]', 'https://www.facebook.com/TheSpace.Mumbai/timeline'
    assert_select 'a[href=?]', 'https://wa.me/919619348427'
  end

  test 'layout links when logged-in as junioradmin' do
    log_in_as(@junioradmin)
    follow_redirect!
    assert_template 'admin/clients/index'
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', admin_clients_path
    assert_select 'a[href=?]', admin_purchases_path
    assert_select 'a[href=?]', admin_wkclasses_path
    assert_select 'a[href=?]', public_timetable_path
    assert_select 'a[href=?]', admin_fitternities_path, count: 0
    assert_select 'a[href=?]', admin_products_path
    assert_select 'a[href=?]', admin_instructors_path, count: 0
    assert_select 'a[href=?]', admin_partners_path, count: 0
    assert_select 'a[href=?]', admin_timetables_path, count: 0 
    assert_select 'a[href=?]', admin_workouts_path, count: 0
    assert_select 'a[href=?]', admin_workout_groups_path, count: 0
    assert_select 'a[href=?]', admin_accounts_path, count: 0
    assert_select 'a[href=?]', superadmin_discount_reasons_path, count: 0
    assert_select 'a[href=?]', superadmin_expenses_path, count: 0    
    assert_select 'a[href=?]', superadmin_expenses_path, count: 0
    assert_select 'a[href=?]', superadmin_regular_expenses_path, count: 0
    assert_select 'a[href=?]', superadmin_instructor_rates_path, count: 0
    assert_select 'a[href=?]', superadmin_orders_path, count: 0
    assert_select 'a[href=?]', superadmin_settings_path, count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=superadmin", count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=admin", count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=junioradmin", count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=instructor", count: 0
    assert_select 'a[href=?]', "/switch_account_role?role=client", count: 0      
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', '/terms&conditions'
    assert_select 'a[href=?]', '/charges&deductions'
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', 'https://www.instagram.com/thespace.juhu/'
    assert_select 'a[href=?]', 'https://www.facebook.com/TheSpace.Mumbai/timeline'
    assert_select 'a[href=?]', 'https://wa.me/919619348427'
  end

  test 'layout links when logged-in as client' do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', client_shop_path(@client)
    assert_select 'a[href=?]', client_history_path(@client)
    assert_select 'a[href=?]', client_book_path(@client)
    assert_select 'a[href=?]', client_timetable_path
    assert_select 'a[href=?]', client_client_path(@client)
    assert_select 'a[href=?]', admin_clients_path, count: 0
    assert_select 'a[href=?]', admin_purchases_path, count: 0
    assert_select 'a[href=?]', admin_wkclasses_path, count: 0 
    assert_select 'a[href=?]', admin_fitternities_path, count: 0
    assert_select 'a[href=?]', admin_products_path, count: 0
    assert_select 'a[href=?]', admin_instructors_path, count: 0
    assert_select 'a[href=?]', admin_partners_path, count: 0
    assert_select 'a[href=?]', admin_timetables_path, count: 0 
    assert_select 'a[href=?]', admin_workouts_path, count: 0
    assert_select 'a[href=?]', admin_workout_groups_path, count: 0
    assert_select 'a[href=?]', admin_accounts_path, count: 0
    assert_select 'a[href=?]', superadmin_expenses_path, count: 0
    assert_select 'a[href=?]', superadmin_discount_reasons_path, count: 0
    assert_select 'a[href=?]', superadmin_expenses_path, count: 0    
    assert_select 'a[href=?]', superadmin_regular_expenses_path, count: 0
    assert_select 'a[href=?]', superadmin_instructor_rates_path, count: 0
    assert_select 'a[href=?]', superadmin_orders_path, count: 0
    assert_select 'a[href=?]', superadmin_settings_path, count: 0
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', '/terms&conditions'
    assert_select 'a[href=?]', '/charges&deductions'
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', 'https://www.instagram.com/thespace.juhu/'
    assert_select 'a[href=?]', 'https://www.facebook.com/TheSpace.Mumbai/timeline'
    assert_select 'a[href=?]', 'https://wa.me/919619348427'
  end

  test 'layout links when logged-in as partner' do
    log_in_as(@account_partner)
    follow_redirect!
    assert_template 'admin/partners/show'
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', admin_workout_groups_path
    assert_select 'a[href=?]', admin_partner_path(@partner)
    assert_select 'a[href=?]', admin_clients_path, count: 0
    assert_select 'a[href=?]', admin_purchases_path, count: 0
    assert_select 'a[href=?]', admin_wkclasses_path, count: 0 
    assert_select 'a[href=?]', admin_fitternities_path, count: 0
    assert_select 'a[href=?]', admin_products_path, count: 0
    assert_select 'a[href=?]', admin_instructors_path, count: 0
    assert_select 'a[href=?]', admin_partners_path, count: 0
    assert_select 'a[href=?]', admin_timetables_path, count: 0 
    assert_select 'a[href=?]', admin_workouts_path, count: 0
    assert_select 'a[href=?]', admin_accounts_path, count: 0
    assert_select 'a[href=?]', superadmin_discount_reasons_path, count: 0
    assert_select 'a[href=?]', superadmin_expenses_path, count: 0    
    assert_select 'a[href=?]', superadmin_expenses_path, count: 0
    assert_select 'a[href=?]', superadmin_regular_expenses_path, count: 0
    assert_select 'a[href=?]', superadmin_instructor_rates_path, count: 0
    assert_select 'a[href=?]', superadmin_orders_path, count: 0
    assert_select 'a[href=?]', superadmin_settings_path, count: 0
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', '/terms&conditions'
    assert_select 'a[href=?]', '/charges&deductions'
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', 'https://www.instagram.com/thespace.juhu/'
    assert_select 'a[href=?]', 'https://www.facebook.com/TheSpace.Mumbai/timeline'
    assert_select 'a[href=?]', 'https://wa.me/919619348427'
  end
end
