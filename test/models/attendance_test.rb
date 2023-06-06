require 'test_helper'
class AttendanceTest < ActiveSupport::TestCase
  def setup
    @attendance =
      Attendance.new(wkclass_id: wkclasses(:SC28Feb).id,
                     purchase_id: purchases(:ChintanUC1Wexp).id)
  end

  test 'should be valid' do
    @attendance.valid?
  end

  test 'associated wkclass must be valid' do
    @attendance.wkclass_id = 4000

    refute_predicate @attendance, :valid?
  end

  test 'associated purchase must be valid' do
    @attendance.purchase_id = 4000

    refute_predicate @attendance, :valid?
  end

  test 'status must be valid' do
    @attendance.status = 'half-booked'

    refute_predicate @attendance, :valid?
  end

  test 'delegated client_name method' do
    assert_equal('Chintan Suchak', @attendance.client_name)
  end
end
