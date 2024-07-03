require "test_helper"

class Admin::BookingCancellationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @no_admin_instructor = accounts(:no_admin_instructor)    
    @booking = bookings(:booking_test)
  end

  test 'should redirect update when not logged in as junioradmin or more senior' do
    original_status = @booking.status
    [nil, @account_client1, @account_client2, @no_admin_instructor].each do |account_holder|
      log_in_as(account_holder)
      patch booking_cancellation_path(@booking), params:
       { booking:
          { id: @booking.id,
            status: 'cancelled late' } }

      assert_equal original_status, @booking.reload.status
      assert_redirected_to login_path
    end
  end
end
