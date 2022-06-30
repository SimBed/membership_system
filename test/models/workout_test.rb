require 'test_helper'

class WorkoutTest < ActiveSupport::TestCase
  def setup
    @workout = Workout.new(name: 'running')
  end

  test 'should be valid' do
    assert_predicate @workout, :valid?
  end

  test 'name should be present' do
    @workout.name = '      '
    refute_predicate @workout, :valid?
  end
end
