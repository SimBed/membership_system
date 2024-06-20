require 'test_helper'

class BookingFormatTest < ActiveSupport::TestCase
  def setup
    @account_client = accounts(:client_for_unlimited)
    @client = @account_client.client
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @day = 0
    @booking_section = 'all'
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
    @booking_format = BookingFormat.new(@tomorrows_class_early, @client, @day, @booking_section)
  end

  test 'booking_link method' do
    # assert_equal 'Amalu', @booking_format.booking_link
  end
end
