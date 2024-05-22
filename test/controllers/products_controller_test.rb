require 'test_helper'
class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @product = products(:unlimited3m)
  end

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_product_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as admin or more senior' do
    [nil, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get products_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get product_path(@product)

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_product_path(@product)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Product.count' do
        post products_path, params:
         { product:
            { max_classes: 1000,
              validity_length: 2,
              validity_unit: 'M',
              workout_group_id: @product.workout_group_id } }
      end
    end
  end

  test 'should redirect update when not logged in as admin or more senior' do
    original_validity_length = @product.validity_length
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      patch product_path(@product), params:
       { product:
          { max_classes: @product.max_classes,
            validity_length: @product.validity_length - 1,
            validity_unit: @product.validity_unit,
            workout_group_id: @product.workout_group_id } }

      assert_equal original_validity_length, @product.reload.validity_length
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Product.count' do
        delete product_path(@product)
      end
    end
  end
end
