require 'test_helper'

class FitternityTest < ActiveSupport::TestCase
  def setup
    @fitternity_ong = Fitternity.last
    @fitternity = Fitternity.new(max_classes: 100,
                                 expiry_date: '2022-05-01')
  end

  test 'should be valid' do
    assert @fitternity.valid?
  end

  test 'classes_remain method' do
    assert_equal 70, @fitternity_ong.classes_remain
    assert_equal 71, @fitternity_ong.classes_remain(provisional: false)
  end


end
