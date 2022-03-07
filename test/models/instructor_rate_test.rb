require "test_helper"

class InstructorRateTest < ActiveSupport::TestCase
  def setup
   @instructor_rate = Instructor_rate.new(rate: 500,
                        date_from: '2022-01-01',
                        instructor_id: ActiveRecord::FixtureSet.identify(:amit)
                        )

   test 'should be valid' do
     assert @instructor_rate.valid?
   end

   test 'instructor should be valid' do
     @instructor_rate.instructor_id = 21
     refute @instructor_rate.valid?
   end
end

end
