require "test_helper"

class ShopOrderTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @account_client_for_ongoing_trial = accounts(:client_for_ongoing_trial)
    @account_client_for_expired_trial = accounts(:client_for_expired_trial)
    @account_new_client = accounts(:client_no_purchases)
    @client_for_unlimited = @account_client.client
    @client_for_ongoing_trial = @account_client_for_ongoing_trial.client
    @client_for_expired_trial = @account_client_for_expired_trial.client
    @client_no_purchases = @account_new_client.client
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
    @product_unlimited1m = products(:unlimited1m)
    @product_unlimited3m = products(:unlimited3m)
    @product_trial = products(:trial)
    @price_Uc1mbase = prices(:Uc1mbase)
    @price_Uc3mbase = prices(:Uc3mbase)
    @price_Uc1mpreexpiry = prices(:Uc1mpreexpiry)
    @price_Uc3mpreexpiry = prices(:Uc3mpreexpiry)
    @price_Uc1mpretrialexpiry = prices(:Uc1mpretrialexpiry)
    @price_Uc3mpretrialexpiry = prices(:Uc3mpretrialexpiry)
    @price_Uc1mposttrialexpiry = prices(:Uc1mposttrialexpiry)
    @price_Uc3mposttrialexpiry = prices(:Uc3mposttrialexpiry)
    @price_trial = prices(:trial)
  end

  test 'test shop items correct for client with ongoing package' do
    log_in_as(@account_client)
    get client_shop_path(@client_for_unlimited)
    assert_template 'client/clients/shop'
    order_params = {product_id: @product_unlimited1m.id,
                    price: 8550,
                    status: 'captured',
                    payment_id: 'razor_xxx',
                    account_id: @account_client.id,
                    client_ui: 'shop page' }
    Order.stub :process_razorpayment, order_params do
      assert_difference 'Order.count' do
      post superadmin_orders_path, params: {product_id: @product_unlimited1m.id,
                                            price_id: @price_Uc1mpreexpiry.id,
                                            account_id: @account_client.id,
                                            client_ui: 'shop page'}
      end
    end
  end
end
