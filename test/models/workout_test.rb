require "test_helper"

class WorkoutTest < ActiveSupport::TestCase
  def setup
    @workout = Workout.new(name: 'running')
  end

  test 'should be valid' do
    assert @workout.valid?
  end

  test 'name should be present' do
    @workout.name = '      '
    refute @workout.valid?
  end
end
