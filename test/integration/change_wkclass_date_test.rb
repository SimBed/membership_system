require "test_helper"

class ChangeWkclassDateTest < ActionDispatch::IntegrationTest
  def setup
    @admin = accounts(:admin)    
    @client = clients(:Maitreyi)
    @product = products(:unlimited1m)
    @price = prices(:Uc1mbase)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @purchase = @client.purchases.create(product_id: @product.id, charge: 9500, price_id: @price.id, dop: '2022-04-01')
    @wkclass1 = @tomorrows_class_early.dup    
  end

  test 'benign wkclass date change' do
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22 April
    # establish 10/4 wkclass
    @wkclass1.update(start_time: @tomorrows_class_early.start_time.advance(days: -12)) # 10 April
    # book for 10 April and 22 April
    @booking1 = Booking.create(wkclass_id: @wkclass1.id, purchase_id: @purchase.id)
    @booking2 = Booking.create(wkclass_id: @tomorrows_class_early.id, purchase_id: @purchase.id)
    log_in_as @admin    
    # update bookings to trigger update purchase so start_date, expiry_date get set
    patch booking_cancellation_path(@booking1), params: { booking: { status: 'attended' } }    
    patch booking_cancellation_path(@booking2), params: { booking: { status: 'attended' } }    
    @purchase.reload
    original_status = @purchase.status
    assert_no_difference ['@purchase.start_date', '@purchase.expiry_date', '@purchase.bookings.no_amnesty.size'] do
      # change date of 22 April class to 15 April (7 days earlier)
      patch wkclass_path(@tomorrows_class_early), params:
      { wkclass: deconstruct_date(@tomorrows_class_early.start_time - 7.days).merge({ instructor_rate_id: @tomorrows_class_early.instructor_rate_id }) }
    end
    @purchase.reload
    assert_equal original_status, @purchase.status
  end

  test 'wkclass date change impacts purchase status' do
    travel_to(@tomorrows_class_early.start_time.beginning_of_day.advance(days: 14)) # 6 May
    # establish wkclasses     
    @wkclass1.update(start_time: @tomorrows_class_early.start_time.advance(days: -12)) # 10 April
    @wkclass2 = @tomorrows_class_early.dup       
    @wkclass2.update(start_time: @tomorrows_class_early.start_time.advance(days: 14)) # 6 May
    # book for 10 April, 22 April and May 6
    @booking1 = Booking.create(wkclass_id: @wkclass1.id, purchase_id: @purchase.id)
    @booking2 = Booking.create(wkclass_id: @tomorrows_class_early.id, purchase_id: @purchase.id)
    @booking3 = Booking.create(wkclass_id: @wkclass2.id, purchase_id: @purchase.id)
    # update bookings to trigger update purchase so start_date, expiry_date get set
    log_in_as @admin    
    patch booking_cancellation_path(@booking1), params: { booking: { status: 'attended' } }
    patch booking_cancellation_path(@booking2), params: { booking: { status: 'attended' } }
    # It is only 22 April, so don't attend May 5 class yet. If we set the 5 May booking to to attended, its status will not change the wkclass
    # falls outside of the expiry date, as we will only cancel booked classes (not attended classes),
    # so the test won't pass as the number of amnesty bookings won't change in that case
    @purchase.reload
    original_status = @purchase.status
    assert_difference '@purchase.bookings.amnesty.size', 1 do
      # change date of 22 April class to April 4 (18 days earlier). 
      patch wkclass_path(@tomorrows_class_early), params:
      { wkclass: deconstruct_date(@tomorrows_class_early.start_time - 18.days).merge({ instructor_rate_id: @tomorrows_class_early.instructor_rate_id }) }
    end
    @purchase.reload
    assert_equal 'expired', @purchase.status 
    assert_equal Date.parse('4 April 2022'), @purchase.start_date
    assert_equal Date.parse('3 May 2022'), @purchase.expiry_date 
  end

end