require 'test_helper'

class FreezesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client3)
    @account_client2 = accounts(:client2)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @purchase = purchases(:purchase_for_freeze)
    @freeze = freezes(:freeze_test)
  end

  # no index method for freezes controller
  # no show method for freezes controller

  test 'should redirect new when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get new_admin_freeze_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      get edit_admin_freeze_path(@freeze)
      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Freeze.count' do
        post admin_freezes_path, params:
         { freeze:
            { purchase_id: @purchase.id,
              start_date: '2021-12-26',
              end_date: '2022-01-02' } }
      end
    end
  end

  test 'should redirect update when not logged in as junioradmin or more senior' do
    original_end_date = @freeze.end_date
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      patch admin_freeze_path(@freeze), params:
       { freeze:
          { purchase_id: @freeze.purchase.id,
            start_date: @freeze.start_date,
            end_date: @freeze.end_date + 5.days } }
      assert_equal original_end_date, @freeze.reload.end_date
      assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Freeze.count' do
        delete admin_freeze_path(@freeze)
      end
    end
  end
end
