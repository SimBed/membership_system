require 'test_helper'

class InstructorRateTest < ActiveSupport::TestCase
  def setup
    @instructor_rate = InstructorRate.new(rate: 500,
                                          date_from: '2022-01-01',
                                          instructor_id: instructors(:amit).id)
  end

  test 'should be valid' do
    assert @instructor_rate.valid?
  end

  test 'instructor should be valid' do
    @instructor_rate.instructor_id = 4000
    refute @instructor_rate.valid?
  end

end
