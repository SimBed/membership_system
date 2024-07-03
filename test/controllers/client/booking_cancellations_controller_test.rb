require "test_helper"

class Client::BookingCancellationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account_client1 = accounts(:client1)
    @client1 = @account_client1.client
    @account_client2 = accounts(:client2)
    @admin = accounts(:admin)
    @superadmin = accounts(:superadmin)
    @junioradmin = accounts(:junioradmin)
    @no_admin_instructor = accounts(:no_admin_instructor)    
    @booking = bookings(:booking_test)
  end

  test 'should redirect update when not logged in as correct client' do
    original_status = @booking.status
    [nil, @account_client2, @no_admin_instructor, @junioradmin, @admin, @superadmin].each do |account_holder|
      log_in_as(account_holder)
      patch client_update_booking_path(@client1, @booking), params:
          { booking_day: '1',
            booking_section: 'group' }

      assert_equal original_status, @booking.reload.status
      assert_redirected_to login_path
    end
  end
end
