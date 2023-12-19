require 'test_helper'

class ShopOrderTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @product_unlimited1m = products(:unlimited1m)
    @price_uc1m_base = prices(:Uc1mbase)
  end

  test 'order created when purchase made from shop' do
    log_in_as(@account_client)
    get client_shop_path(@account_client.client)

    assert_template 'client/clients/shop'
    order_params = { product_id: @product_unlimited1m.id,
                     price: 8550,
                     status: 'captured',
                     payment_id: 'razor_xxx',
                     account_id: @account_client.id,
                     client_ui: 'shop page' }

    Order.stub :process_razorpayment, order_params do
      assert_difference 'Order.count' do
        post superadmin_orders_path, params: { product_id: @product_unlimited1m.id,
                                               price_id: @price_uc1m_base.id,
                                               account_id: @account_client.id,
                                               client_ui: 'shop page' }
      end
    end
  end
end
