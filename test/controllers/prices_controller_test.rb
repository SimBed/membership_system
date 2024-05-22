require 'test_helper'

class PricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @product = products(:unlimited3m)
    @price = prices(:Uc3mbase)
  end

  # no index method for prices controller
  # no show method for prices controller

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_price_path(product_id: @product.id)

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_price_path(@price)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Price.count' do
        post prices_path, params:
         { price:
            { price: 5000,
              date_from: '2022-01-01',
              date_until: '2122-01-01',
              product_id: @price.product.id } }
      end
    end
  end

  test 'should redirect update when not logged in as admin or more senior' do
    original_price = @price.price
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      patch price_path(@price), params:
       { price:
          { price: @price.price + 100,
            date_from: @price.date_from,
            date_until: @price.date_until,
            product_id: @price.product_id } }

      assert_equal original_price, @price.reload.price
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Price.count' do
        delete price_path(@price)
      end
    end
  end
end
