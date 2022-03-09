require 'test_helper'
class PurchasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @purchase1 = purchases(:aparna_package)
  end

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_admin_purchase_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get admin_purchases_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as admin or more senior' do
    [nil, @purchase1.client.account, @account_client2, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get admin_purchase_path(@purchase1)
      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior' do
    [nil, @purchase1.client.account, @account_client2, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_admin_purchase_path(@purchase1)
      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Purchase.count' do
        post admin_purchases_path, params:
         { purchase:
            { client_id: @account_client1.clients.first.id,
              product_id: @purchase1.product_id,
              payment: 1000,
              dop: '2022-02-15',
              payment_mode: 'Cash',
              price_id: @purchase1.price.id
             }
            }
        end
      end
    end

  test 'should redirect update when not logged in as admin or more senior' do
    original_payment = @purchase1.payment
    [nil, @account_client1, @account_client2, @account_partner1, @junioradmin].each do |account_holder|
    log_in_as(account_holder)
    patch admin_purchase_path(@purchase1), params:
     { purchase:
        { client_id: @purchase1.client_id,
          product_id: @purchase1.product_id,
          payment: @purchase1.payment + 500,
          dop: @purchase1.dop,
          payment_mode: @purchase1.payment_mode,
          price_id: @purchase1.price_id
         }
        }
    assert_equal original_payment, @purchase1.reload.payment
    assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Purchase.count' do
        delete admin_purchase_path(@purchase1)
      end
    end
  end

end
