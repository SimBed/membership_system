require 'test_helper'

class Admin::BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @no_admin_instructor = accounts(:no_admin_instructor)    
    @purchase = purchases(:AparnaUC1Mong)
    @booking = bookings(:booking_test)
    @wkclass = wkclasses(:wkclass_mat)
  end

  test 'should redirect create when not logged in as junior admin or more senior' do
    [nil, @account_client1, @account_client2, @no_admin_instructor].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Booking.count' do
        post bookings_path, params:
         { booking:
            { wkclass_id: @wkclass.id,
              purchase_id: @purchase.id } }
      end
    end
  end

  test 'should redirect destroy when not logged in as junioradmin or more senior' do
    [nil, @account_client1, @account_client2, @no_admin_instructor].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Booking.count' do
        delete booking_path(@booking)
      end
    end
  end
end
