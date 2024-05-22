require 'test_helper'

class AdjustmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @purchase1 = purchases(:AparnaUC1Mong)
    @adjustment = adjustments(:adjustment2)
  end

  # no index method for adjustments controller
  # no show method for adjustments controller

  test 'should redirect new when not logged in as junioradmin or more senior' do
    [nil, @account_client1].each do |account_holder|
      log_in_as(account_holder)
      get new_adjustment_path

      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as junioradmin or more senior' do
    [nil, @purchase1.client.account, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      get edit_adjustment_path(@adjustment)

      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Adjustment.count' do
        post adjustments_path, params:
         { adjustment:
            { purchase_id: @purchase1.id,
              adjustment: 10 } }
      end
    end
  end

  test 'should redirect update when not logged in as junioradmin or more senior' do
    original_adjustment = @adjustment.adjustment
    [nil, @account_client1, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      patch adjustment_path(@adjustment), params:
       { adjustment:
          { purchase_id: @purchase1.id,
            adjustment: @adjustment.adjustment + 5 } }

      assert_equal original_adjustment, @adjustment.reload.adjustment
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Adjustment.count' do
        delete adjustment_path(@adjustment)
      end
    end
  end
end
