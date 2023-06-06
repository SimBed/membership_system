require 'test_helper'

class WorkoutTest < ActiveSupport::TestCase
  def setup
    @workout = Workout.new(name: ' my running class ')
  end

  test 'should be valid' do
    assert_predicate @workout, :valid?
  end

  test 'name should be present' do
    @workout.name = '      '

    refute_predicate @workout, :valid?
  end

  test 'name should get prettified on save' do
    @workout.save

    assert_equal('My Running Class', @workout.name)
  end
end
