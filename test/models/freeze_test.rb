require 'test_helper'

class FreezeTest < ActiveSupport::TestCase
  def setup
    @freeze = Freeze.new(purchase_id: ActiveRecord::FixtureSet.identify(:aparna_package),
                         start_date: '2022-02-05',
                         end_date: '2022-02-15',
                         note: 'caca is here')
  end

  test 'should be valid' do
    assert @freeze.valid?
  end

  test 'duration should not be too short' do
    @freeze.end_date = @freeze.start_date + 3.days
    refute @freeze.valid?
  end

  test 'purchase should be valid' do
    @freeze.purchase_id = 21
    refute @freeze.valid?
  end

  test 'duration' do
    assert_equal 11, @freeze.duration
  end
end
