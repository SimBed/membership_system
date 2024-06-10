require 'test_helper'
class PurchasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
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
    [nil, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get new_purchase_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as junioradmin or more senior' do
    [nil, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get purchases_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as junioradmin or more senior' do
    [nil, @purchase1.client.account, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      get purchase_path(@purchase1)

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as junioradmin or more senior' do
    [nil, @purchase1.client.account, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      get edit_purchase_path(@purchase1)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Purchase.count' do
        post purchases_path, params:
         { purchase:
            { client_id: @account_client1.client.id,
              product_id: @purchase1.product_id,
              charge: 1000,
              dop: '2022-02-15',
              price: @trial_price } }
      end
    end
  end

  test 'should redirect update when not logged in as junioradmin or more senior' do
    original_payment = @purchase1.charge
    [nil, @purchase1.client.account, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      patch purchase_path(@purchase1), params:
       { purchase:
          { client_id: @purchase1.client_id,
            product_id: @purchase1.product_id,
            charge: @purchase1.charge + 500,
            dop: @purchase1.dop,
            price: @trial_price } }

      assert_equal original_payment, @purchase1.reload.charge
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as junioradmin or more senior' do
    [nil, @purchase1.client.account, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Purchase.count' do
        delete purchase_path(@purchase1)
      end
    end
  end

  test 'should redirect create when client has already had a trial and a trial is purchased' do
    log_in_as(@admin)
    assert_no_difference 'Purchase.count' do
      post purchases_path, params:
       { purchase:
          { client_id: @client_trial_expired.id,
            product_id: @product_trial.id,
            charge: 1500,
            dop: '2022-02-15',
            price: prices(:trial),
            renewal_discount_id: @discount.id,
            status_discount_id: @discount.id,
            oneoff_discount_id: @discount.id,
            payment_attributes: {amount: 1500, payment_mode: 'Cash'} } }
    end
  end
end
