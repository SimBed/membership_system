require 'test_helper'

class WorkoutGroupTest < ActiveSupport::TestCase
  def setup
    @workout1 = workouts(:hiit)
    @workout2 = workouts(:mobility)
    @workout_group = WorkoutGroup.new(
      name: 'Dance', renewable: true, requires_account: true,
      workout_ids: [@workout1.id, @workout2.id],
      service: 'Group'
    )
  end

  test 'should be valid' do
    assert_predicate @workout_group, :valid?
  end

  test 'name should be present' do
    @workout_group.name = '      '

    refute_predicate @workout_group, :valid?
  end

  test 'workout_ids should be present' do
    @workout_group.workout_ids = []

    refute_predicate @workout_group, :valid?
  end

  test '#revenue?' do
    period = month_period('1 October 2021')
    assert_equal 6000, @workout_group.revenue('Purchase', period)
    assert_equal 650, @workout_group.revenue('Freeze', period)
    assert_equal 0, @workout_group.revenue('Restart', period)
    assert_equal 6650, @workout_group.revenue('all', period)
  end 
end
