require 'test_helper'

class DiscountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @discount = discounts(:none)
    @discount_reason = discount_reasons(:firstpackage)
    @account_client = clients(:client_ekta_unlimited)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
  end

  test 'should redirect new when not logged in as superadmin' do
    [nil, @account_client, @admin, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_discount_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as superadmin' do
    [nil, @account_client, @admin, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_discount_path(@discount)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as superadmin' do
    [nil, @account_client, @admin, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Discount.count' do
        post discounts_path, params:
         { discount:
            { discount_reason: @discount_reason,
              percent: 0,
              fixed: 10_000,
              group: true,
              pt: true,
              online: true,
              start_date: '2023-01-01',
              end_date: '2123-01-01' } }
      end
    end
  end

  test 'should redirect update when not logged in as superadmin' do
    original_discount = @discount.percent
    [nil, @account_client, @admin, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      patch discount_path(@discount), params:
       { discount: { percent: 50 } }

      assert_equal original_discount, @discount.reload.percent
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as junioradmin or more senior' do
    [nil, @account_client, @admin, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Discount.count' do
        delete discount_path(@discount)
      end
    end
  end
end
