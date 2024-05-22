require 'test_helper'

class WorkoutGroupTest < ActiveSupport::TestCase
  def setup
    @workout1 = workouts(:hiit)
    @workout2 = workouts(:mobility)
    @workout_group = WorkoutGroup.new(
      name: 'Dance', gst_applies: true, requires_invoice: true,
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
end
