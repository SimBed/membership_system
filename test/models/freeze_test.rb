require 'test_helper'

class FreezeTest < ActiveSupport::TestCase
  def setup
    @freeze = Freeze.new(purchase_id: purchases(:AnushkaUC3Mong).id,
                         start_date: '2022-03-08',
                         end_date: '2022-03-14',
                         note: 'caca is here')
  end

  test 'should be valid' do
    assert_predicate @freeze, :valid?
  end

  test 'duration should not be too short' do
    @freeze.end_date = @freeze.start_date + 1.day

    refute_predicate @freeze, :valid?
  end

  test 'period should not overlap an attendance' do
    # attendances on "Tue 22 Feb 22", "Mon 28 Feb 22", "Wed 23 Feb 22", "Wed 23 Feb 22", "Tue 25 Jan 22"
    @freeze.start_date = Date.parse('2022-02-27')

    refute_predicate @freeze, :valid?
  end

  test 'purchase should be valid' do
    @freeze.purchase_id = 4000

    refute_predicate @freeze, :valid?
  end

  test 'duration method' do
    assert_equal 7, @freeze.duration
  end
end
