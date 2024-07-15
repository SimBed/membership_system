require 'test_helper'

class ShopOrderTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @product_unlimited1m = products(:unlimited1m)
    @price_uc1m_base = prices(:Uc1mbase)
    @purchase_to_freeze = purchases(:ekta_unlimited)  # start_date: 21/3/2022, expiry_date: 20/6/2022
  end

  test 'purchase created when payment made from shop' do
    log_in_as(@account_client)
    get client_shop_path(@account_client.client)

    assert_template 'client/dynamic_pages/shop'
    order_params = { razorpay_payment_id: 'x',
                     razorpay_signature: 'y',
                     product_id: @product_unlimited1m.id,
                     price_id: @price_uc1m_base.id,
                     price: 8550,
                     account_id: @account_client.id,
                     client_ui: 'shop page' }

    # This is not an exact simulation of what happens in practice, but it is pretty close
    Razorpay::Utility.stub :verify_payment_signature, true do
      Order.stub :payment_status_check, 'captured' do
        assert_difference [ 'Purchase.count', 'Payment.count' ], 1 do
        post orders_path, params: { amount: 855000 }
        assert_response :success
        post verify_payment_path(purchase_type: 'membership', params: order_params)
        end
      end
    end
  end

  test 'freeze created when payment made through package modification' do
    log_in_as(@account_client)
    follow_redirect!

    assert_template 'client/bookings/index'
    order_params = { razorpay_payment_id: 'x',
                     razorpay_signature: 'y',
                     purchase_id: @purchase_to_freeze.id,
                     price: 8550,
                     start_date: Date.parse('1/5/2022'),
                     account_id: @account_client.id }

    Razorpay::Utility.stub :verify_payment_signature, true do
      Order.stub :payment_status_check, 'captured' do
        assert_difference [ 'Freeze.count', 'Payment.count' ], 1 do
        post orders_path, params: { amount: 855000 }
        assert_response :success
        post verify_payment_path(purchase_type: 'membership_freeze', params: order_params)
        end
      end
    end
  end
end
