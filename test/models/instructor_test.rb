require "test_helper"

class InstructorTest < ActiveSupport::TestCase
  def setup
    @instructor = Instructor.new(first_name: 'Aadrak', last_name: 'Scaredy')
  end

  test 'should be valid' do
    assert @instructor.valid?
  end
end
