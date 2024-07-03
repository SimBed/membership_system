require 'test_helper'

class Admin::BookingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @client1 = @account_client1.client
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @no_admin_instructor = accounts(:no_admin_instructor)    
    @purchase = purchases(:AparnaUC1Mong)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
  end

  test 'should redirect index when not logged in as correct client' do
    [nil, @account_client2, @no_admin_instructor, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder) 
      get client_bookings_path(@client1)
      assert_redirected_to login_path
    end
  end

  test 'should redirect create when not logged in as correct client' do
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)
    [nil, @account_client2, @no_admin_instructor, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      assert_no_difference 'Booking.count' do
        post client_create_booking_path(@client1), params:
         { booking:
            { wkclass_id: @tomorrows_class_early.id,
              purchase_id: @purchase.id } }
      end
    end
  end

end
