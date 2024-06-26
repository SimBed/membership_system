require 'test_helper'

class Superadmin::InstructorRatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @instructor_rate = instructor_rates(:amit_pt)
  end

  # no show method for instructor_rates controller

  test 'should redirect new when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get new_instructor_rate_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get instructor_rates_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      get edit_instructor_rate_path(@instructor_rate)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'InstructorRate.count' do
        post instructor_rates_path, params:
         { instructor_rate:
            { rate: 1000,
              date_from: '2022-03-01',
              instructor_id: @instructor_rate.instructor_id } }
      end
    end
  end

  test 'should redirect update when not logged in as superadmin' do
    original_rate = @instructor_rate.rate
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      patch instructor_rate_path(@instructor_rate), params:
       { instructor_rate:
          { rate: @instructor_rate.rate + 500,
            date_from: @instructor_rate.date_from,
            instructor_id: @instructor_rate.instructor_id } }

      assert_equal original_rate, @instructor_rate.reload.rate
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as superadmin' do
    [nil, @account_client1, @junioradmin, @admin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'InstructorRate.count' do
        delete instructor_rate_path(@instructor_rate)
      end
    end
  end
 
end
