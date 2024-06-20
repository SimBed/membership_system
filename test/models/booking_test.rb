require 'test_helper'
class BookingTest < ActiveSupport::TestCase
  def setup
    @booking =
      Booking.new(wkclass_id: wkclasses(:SC28Feb).id,
                     purchase_id: purchases(:ChintanUC1Wexp).id)
  end

  test 'should be valid' do
    @booking.valid?
  end

  test 'associated wkclass must be valid' do
    @booking.wkclass_id = 4000

    refute_predicate @booking, :valid?
  end

  test 'associated purchase must be valid' do
    @booking.purchase_id = 4000

    refute_predicate @booking, :valid?
  end

  test 'status must be valid' do
    @booking.status = 'half-booked'

    refute_predicate @booking, :valid?
  end

  test 'delegated client_name method' do
    assert_equal('Chintan Suchak', @booking.client_name)
  end
end
