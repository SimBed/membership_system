require 'test_helper'

class FitternitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_partner1 = accounts(:partner1)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @fitternity = fitternities(:two_ongoing)
  end

  test 'should redirect new when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get new_admin_fitternity_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect index when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get admin_fitternities_path
      assert_redirected_to login_path
    end
  end

  test 'should redirect show when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get admin_fitternity_path(@fitternity)
      assert_redirected_to login_path
    end
  end

  test 'should redirect edit when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      get edit_admin_fitternity_path(@fitternity)
      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as admin or more senior' do
    [nil, @account_client1, @account_client2, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Fitternity.count' do
        post admin_fitternities_path, params:
         { fitternity:
            { max_classes: 100,
              expiry_date: '2022-03-01'
             }
            }
        end
      end
    end

  test 'should redirect update when not logged in as admin or more senior' do
    original_max_classes = @fitternity.max_classes
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
    log_in_as(account_holder)
    patch admin_fitternity_path(@fitternity), params:
     { fitternity:
        { max_classes: @fitternity.max_classes + 100,
          expiry_date: @fitternity.expiry_date
         }
        }
    assert_equal original_max_classes, @fitternity.reload.max_classes
    assert_redirected_to login_path
    end
  end

  test 'should redirect destroy when not logged in as admin or more senior' do
    [nil, @account_client1, @account_partner1, @junioradmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Fitternity.count' do
        delete admin_fitternity_path(@fitternity)
      end
    end
  end
end
