require 'test_helper'

class WorkoutGroupTest < ActiveSupport::TestCase
  def setup
    @partner = partners(:Arnie)
    @workout1 = workouts(:hiit)
    @workout2 = workouts(:mobility)
    @workout_group = WorkoutGroup.new(
      name: 'Dance', partner_id: @partner.id, partner_share: 50,
      gst_applies: true, requires_invoice: true,
      workout_ids: [@workout1.id, @workout2.id]
    )
  end

  test 'should be valid' do
    assert @workout_group.valid?
  end

  test 'name should be present' do
    @workout_group.name = '      '
    refute @workout_group.valid?
  end

  test 'partner_share should be present' do
    @workout_group.partner_share = ''
    refute @workout_group.valid?
  end

  test 'workout_ids should be present' do
    @workout_group.workout_ids = []
    refute @workout_group.valid?
  end
end
