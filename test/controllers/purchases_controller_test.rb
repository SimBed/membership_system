require 'test_helper'
class PurchasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @purchase1 = purchases(:AparnaUC1Mong)
    @client_trial_expired = clients(:client_trial_expired)
    @product_trial = products(:trial)
    @trial_price = prices(:trial)
    @discount = discounts(:none)
  end

  test 'should redirect new when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get new_admin_purchase_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get admin_purchases_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as junioradmin or more senior' do
    [nil, @purchase1.client.account, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get admin_purchase_path(@purchase1)

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as junioradmin or more senior' do
    [nil, @purchase1.client.account, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get edit_admin_purchase_path(@purchase1)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Purchase.count' do
        post admin_purchases_path, params:
         { purchase:
            { client_id: @account_client1.client.id,
              product_id: @purchase1.product_id,
              payment: 1000,
              dop: '2022-02-15',
              payment_mode: 'Cash',
              price: @trial_price } }
      end
    end
  end

  test 'should redirect update when not logged in as junioradmin or more senior' do
    original_payment = @purchase1.payment
    [nil, @purchase1.client.account, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      patch admin_purchase_path(@purchase1), params:
       { purchase:
          { client_id: @purchase1.client_id,
            product_id: @purchase1.product_id,
            payment: @purchase1.payment + 500,
            dop: @purchase1.dop,
            payment_mode: @purchase1.payment_mode,
            price: @trial_price } }

      assert_equal original_payment, @purchase1.reload.payment
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @purchase1.client.account, @account_client2, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Purchase.count' do
        delete admin_purchase_path(@purchase1)
      end
    end
  end

  test 'should redirect create when client has already had a trial and a trial is purchased' do
    log_in_as(@admin)
    assert_no_difference 'Purchase.count' do
      post admin_purchases_path, params:
       { purchase:
          { client_id: @client_trial_expired.id,
            product_id: @product_trial.id,
            payment: 1500,
            dop: '2022-02-15',
            payment_mode: 'Cash',
            price: prices(:trial),
            renewal_discount_id: @discount.id,
            status_discount_id: @discount.id,
            oneoff_discount_id: @discount.id } }
    end
  end
end
