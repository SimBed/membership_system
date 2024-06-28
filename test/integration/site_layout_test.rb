require 'test_helper'

class SiteLayoutTest < ActionDispatch::IntegrationTest
  setup do
    @junioradmin = accounts(:junioradmin)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @account_client = accounts(:client1)
    @account_client_pt = accounts(:client_pt)
    @client = @account_client.client
    @client_pt = @account_client_pt.client
  end

  test 'layout links when logged-in as superadmin' do
    log_in_as(@superadmin)
    follow_redirect!

    assert_template 'admin/clients/index'
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', clients_path
    assert_select 'a[href=?]', purchases_path
    assert_select 'a[href=?]', wkclasses_path
    assert_select 'a[href=?]', public_format_timetable_path
    assert_select 'a[href=?]', employee_accounts_path
    assert_select 'a[href=?]', achievements_path
    assert_select 'a[href=?]', blast_path
    assert_select 'a[href=?]', challenges_path
    assert_select 'a[href=?]', declarations_path
    assert_select 'a[href=?]', discounts_path
    assert_select 'a[href=?]', discount_reasons_path
    assert_select 'a[href=?]', freezes_path
    assert_select 'a[href=?]', instructors_path
    assert_select 'a[href=?]', instructor_rates_path
    assert_select 'a[href=?]', strength_markers_path
    assert_select 'a[href=?]', other_services_path
    assert_select 'a[href=?]', payments_path
    assert_select 'a[href=?]', products_path
    assert_select 'a[href=?]', restarts_path
    assert_select 'a[href=?]', superadmin_settings_path
    assert_select 'a[href=?]', timetables_path
    assert_select 'a[href=?]', workouts_path
    assert_select 'a[href=?]', workout_groups_path
    assert_select 'div.dropdown-item', '*superadmin'
    assert_select 'a[href=?]', '/switch_account_role?role=superadmin', count: 0
    assert_select 'a[href=?]', '/switch_account_role?role=admin'
    assert_select 'a[href=?]', '/switch_account_role?role=junioradmin'
    assert_select 'a[href=?]', '/switch_account_role?role=instructor'
    assert_select 'a[href=?]', '/switch_account_role?role=client'
    assert_select 'a[href=?]', logout_path
    # assert_select 'form.button_to[action=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', terms_and_conditions_path
    assert_select 'a[href=?]', charges_and_deductions_path
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', contact_path
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
    assert_select 'a[href=?]', clients_path
    assert_select 'a[href=?]', purchases_path
    assert_select 'a[href=?]', wkclasses_path
    assert_select 'a[href=?]', public_format_timetable_path
    assert_select 'a[href=?]', employee_accounts_path, count:0
    assert_select 'a[href=?]', achievements_path
    assert_select 'a[href=?]', blast_path, count:0
    assert_select 'a[href=?]', challenges_path, count:0
    assert_select 'a[href=?]', declarations_path
    assert_select 'a[href=?]', discounts_path, count:0
    assert_select 'a[href=?]', discount_reasons_path, count:0
    assert_select 'a[href=?]', freezes_path
    assert_select 'a[href=?]', instructors_path
    assert_select 'a[href=?]', instructor_rates_path, count:0
    assert_select 'a[href=?]', strength_markers_path
    assert_select 'a[href=?]', other_services_path, count:0
    assert_select 'a[href=?]', payments_path, count:0
    assert_select 'a[href=?]', products_path
    assert_select 'a[href=?]', restarts_path
    assert_select 'a[href=?]', superadmin_settings_path, count:0
    assert_select 'a[href=?]', timetables_path
    assert_select 'a[href=?]', workouts_path
    assert_select 'a[href=?]', workout_groups_path
    assert_select 'div.dropdown-item', '*admin'
    assert_select 'a[href=?]', '/switch_account_role?role=superadmin', count: 0
    assert_select 'a[href=?]', '/switch_account_role?role=admin', count: 0
    assert_select 'a[href=?]', '/switch_account_role?role=junioradmin'
    assert_select 'a[href=?]', '/switch_account_role?role=instructor', count: 0
    assert_select 'a[href=?]', '/switch_account_role?role=client', count: 0
    assert_select 'a[href=?]', logout_path
    # assert_select 'form.button_to[action=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', terms_and_conditions_path
    assert_select 'a[href=?]', charges_and_deductions_path
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', contact_path    
    assert_select 'a[href=?]', 'https://www.instagram.com/thespace.juhu/'
    assert_select 'a[href=?]', 'https://www.facebook.com/TheSpace.Mumbai/timeline'
    assert_select 'a[href=?]', 'https://wa.me/919619348427'
  end

  test 'layout links when logged-in as junioradmin' do
    log_in_as(@junioradmin)
    follow_redirect!

    assert_template 'admin/clients/index'
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', clients_path
    assert_select 'a[href=?]', purchases_path
    assert_select 'a[href=?]', wkclasses_path
    assert_select 'a[href=?]', public_format_timetable_path
    assert_select 'a[href=?]', employee_accounts_path, count:0
    assert_select 'a[href=?]', achievements_path, count:0
    assert_select 'a[href=?]', blast_path, count:0
    assert_select 'a[href=?]', challenges_path, count:0
    assert_select 'a[href=?]', declarations_path
    assert_select 'a[href=?]', discounts_path, count:0
    assert_select 'a[href=?]', discount_reasons_path, count:0
    assert_select 'a[href=?]', freezes_path
    assert_select 'a[href=?]', instructors_path, count:0
    assert_select 'a[href=?]', instructor_rates_path, count:0
    assert_select 'a[href=?]', strength_markers_path, count:0
    assert_select 'a[href=?]', other_services_path, count:0
    assert_select 'a[href=?]', payments_path, count:0
    assert_select 'a[href=?]', products_path
    assert_select 'a[href=?]', restarts_path
    assert_select 'a[href=?]', superadmin_settings_path, count:0
    assert_select 'a[href=?]', timetables_path, count:0
    assert_select 'a[href=?]', workouts_path, count:0
    assert_select 'a[href=?]', workout_groups_path, count:0
    assert_select 'a[href=?]', '/switch_account_role?role=superadmin', count: 0
    assert_select 'a[href=?]', '/switch_account_role?role=admin', count: 0
    assert_select 'a[href=?]', '/switch_account_role?role=junioradmin', count: 0
    assert_select 'a[href=?]', '/switch_account_role?role=instructor', count: 0
    assert_select 'a[href=?]', '/switch_account_role?role=client', count: 0
    assert_select 'a[href=?]', logout_path
    # assert_select 'form.button_to[action=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', terms_and_conditions_path
    assert_select 'a[href=?]', charges_and_deductions_path
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', contact_path    
    
    assert_select 'a[href=?]', 'https://www.instagram.com/thespace.juhu/'
    assert_select 'a[href=?]', 'https://www.facebook.com/TheSpace.Mumbai/timeline'
    assert_select 'a[href=?]', 'https://wa.me/919619348427'
  end

  test 'layout links when logged-in as non-pt client' do
    log_in_as(@account_client)
    follow_redirect!

    assert_template 'client/bookings/index'
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', client_shop_path(@client)
    assert_select 'a[href=?]', client_history_path(@client)
    assert_select 'a[href=?]', client_bookings_path(@client)
    assert_select 'a[href=?]', client_pt_path(@client), count: 0
    assert_select 'a[href=?]', client_timetable_path
    assert_select 'a[href=?]', client_profile_path(@client)
    assert_select 'a[href=?]', strength_markers_path
    assert_select 'a[href=?]', client_declaration_path(@client)
    assert_select 'a[href=?]', clients_path, count: 0
    assert_select 'a[href=?]', purchases_path, count: 0
    assert_select 'a[href=?]', wkclasses_path, count: 0
    assert_select 'a[href=?]', fitternities_path, count: 0
    assert_select 'a[href=?]', products_path, count: 0
    assert_select 'a[href=?]', instructors_path, count: 0
    assert_select 'a[href=?]', timetables_path, count: 0
    assert_select 'a[href=?]', workouts_path, count: 0
    assert_select 'a[href=?]', workout_groups_path, count: 0
    assert_select 'a[href=?]', employee_accounts_path, count: 0
    assert_select 'a[href=?]', expenses_path, count: 0
    assert_select 'a[href=?]', discount_reasons_path, count: 0
    assert_select 'a[href=?]', expenses_path, count: 0
    assert_select 'a[href=?]', regular_expenses_path, count: 0
    assert_select 'a[href=?]', instructor_rates_path, count: 0
    assert_select 'a[href=?]', orders_path, count: 0
    assert_select 'a[href=?]', superadmin_settings_path, count: 0
    assert_select 'a[href=?]', logout_path
    # assert_select 'form.button_to[action=?]', logout_path
    assert_select 'a[href=?]', login_path, count: 0

    assert_select 'a[href=?]', about_path
    assert_select 'a[href=?]', terms_and_conditions_path
    assert_select 'a[href=?]', charges_and_deductions_path
    assert_select 'a[href=?]', privacy_policy_path
    assert_select 'a[href=?]', payment_policy_path
    assert_select 'a[href=?]', contact_path    
    assert_select 'a[href=?]', 'https://www.instagram.com/thespace.juhu/'
    assert_select 'a[href=?]', 'https://www.facebook.com/TheSpace.Mumbai/timeline'
    assert_select 'a[href=?]', 'https://wa.me/919619348427'
  end

  test 'layout links when logged-in as pt client' do
    log_in_as(@account_client_pt)
    follow_redirect!

    assert_template 'client/bookings/index'
    assert_select 'a[href=?]', root_path
    assert_select 'a[href=?]', client_shop_path(@client_pt)
    assert_select 'a[href=?]', client_history_path(@client_pt)
    assert_select 'a[href=?]', client_bookings_path(@client_pt)
    assert_select 'a[href=?]', client_pt_path(@client_pt), count: 1
    assert_select 'a[href=?]', client_timetable_path
    assert_select 'a[href=?]', client_profile_path(@client_pt)
    assert_select 'a[href=?]', strength_markers_path
    assert_select 'a[href=?]', new_client_declaration_path(@client_pt)    
    assert_select 'a[href=?]', client_profile_path(@client_pt)
  end
end
