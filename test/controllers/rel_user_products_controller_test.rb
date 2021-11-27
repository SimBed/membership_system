require "test_helper"

class RelUserProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rel_user_product = rel_user_products(:one)
  end

  test "should get index" do
    get rel_user_products_url
    assert_response :success
  end

  test "should get new" do
    get new_rel_user_product_url
    assert_response :success
  end

  test "should create rel_user_product" do
    assert_difference('RelUserProduct.count') do
      post rel_user_products_url, params: { rel_user_product: { dop: @rel_user_product.dop, payment: @rel_user_product.payment, product_id: @rel_user_product.product_id, user_id: @rel_user_product.user_id } }
    end

    assert_redirected_to rel_user_product_url(RelUserProduct.last)
  end

  test "should show rel_user_product" do
    get rel_user_product_url(@rel_user_product)
    assert_response :success
  end

  test "should get edit" do
    get edit_rel_user_product_url(@rel_user_product)
    assert_response :success
  end

  test "should update rel_user_product" do
    patch rel_user_product_url(@rel_user_product), params: { rel_user_product: { dop: @rel_user_product.dop, payment: @rel_user_product.payment, product_id: @rel_user_product.product_id, user_id: @rel_user_product.user_id } }
    assert_redirected_to rel_user_product_url(@rel_user_product)
  end

  test "should destroy rel_user_product" do
    assert_difference('RelUserProduct.count', -1) do
      delete rel_user_product_url(@rel_user_product)
    end

    assert_redirected_to rel_user_products_url
  end
end
