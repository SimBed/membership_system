require "test_helper"

class AttendanceTest < ActiveSupport::TestCase
  def setup
    @attendance =
      Attendance.new(wkclass_id: ActiveRecord::FixtureSet.identify(:wkclass1),
                     purchase_id: ActiveRecord::FixtureSet.identify(:aparna_package)
                    )
  end

  test 'should be valid' do
    @attendance.valid?
  end

  test 'associated wkclass must be valid' do
    @attendance.wkclass_id = 21
    refute @attendance.valid?
  end

  test 'associated purchase must be valid' do
    @attendance.purchase_id = 21
    refute @attendance.valid?
  end

  test 'status must be valid' do
    @attendance.status = 'half-booked'
    refute @attendance.valid?
  end
end
