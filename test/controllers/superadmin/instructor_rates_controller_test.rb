require 'test_helper'

class Superadmin::InstructorRatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @purchase1 = purchases(:aparna_package)
    @instructor_rate = instructor_rates(:amit_rate)
  end

  # no show method for instructor_rates controller

  test 'should redirect new when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get new_superadmin_instructor_rate_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get superadmin_instructor_rates_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get edit_superadmin_instructor_rate_path(@instructor_rate)
      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'InstructorRate.count' do
        post superadmin_instructor_rates_path, params:
         { instructor_rate:
            { rate: 1000,
              date_from: '2022-03-01',
              instructor_id: @instructor_rate.instructor_id } }
      end
    end
  end

  test 'should redirect update when not logged in as superadmin' do
    original_rate = @instructor_rate.rate
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      patch superadmin_instructor_rate_path(@instructor_rate), params:
       { instructor_rate:
          { rate: @instructor_rate.rate + 500,
            date_from: @instructor_rate.date_from,
            instructor_id: @instructor_rate.instructor_id } }
      assert_equal original_rate, @instructor_rate.reload.rate
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as superadmin' do
    [nil, @account_client1, @account_partner1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'InstructorRate.count' do
        delete superadmin_instructor_rate_path(@instructor_rate)
      end
    end
  end

  # test 'should redirect index when not logged in as senioradmin' do
  #   get superadmin_instructor_rates_url
  #   assert_redirected_to login_path
  #   log_in_as(@client1)
  #   get superadmin_instructor_rates_url
  #   assert_redirected_to login_path
  #   log_in_as(@partner1)
  #   get superadmin_instructor_rates_url
  #   assert_redirected_to login_path
  #   log_in_as(@junioradmin)
  #   get superadmin_instructor_rates_url
  #   assert_redirected_to login_path
  #   log_in_as(@admin)
  #   get superadmin_instructor_rates_url
  #   assert_redirected_to login_path
  # end
end
