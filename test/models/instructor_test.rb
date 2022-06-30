require 'test_helper'

class InstructorTest < ActiveSupport::TestCase
  def setup
    @instructor = Instructor.new(first_name: 'Aadrak', last_name: 'Scaredy')
  end

  test 'should be valid' do
    assert_predicate @instructor, :valid?
  end

  test 'first name should be present' do
    @instructor.first_name = '     '
    refute_predicate @instructor, :valid?
  end

  test 'last name should be present' do
    @instructor.last_name = '     '
    refute_predicate @instructor, :valid?
  end

  test 'full name should be unique' do
    duplicate_named_instructor = Instructor.new(first_name: @instructor.first_name, last_name: @instructor.last_name)
    @instructor.save
    refute_predicate duplicate_named_instructor, :valid?
  end
end
