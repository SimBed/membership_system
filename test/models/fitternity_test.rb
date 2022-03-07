require 'test_helper'

class FitternityTest < ActiveSupport::TestCase
  def setup
    @fitternity = Fitternity.new(max_classes: 100,
                                 expiry_date: '2022-05-01')
  end

  test 'should be valid' do
    assert @fitternity.valid?
  end
end
