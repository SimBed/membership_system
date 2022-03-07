# frozen_string_literal: true

require 'test_helper'
class AdjustmentTest < ActiveSupport::TestCase
  def setup
    @adjustment = Adjustment.new(purchase_id: ActiveRecord::FixtureSet.identify(:aparna_package),
                                 adjustment: 10)
  end

  test 'should be valid' do
    assert @adjustment.valid?
  end

  test 'adjustment should be integer' do
    @adjustment.adjustment = 10.5
    refute @adjustment.valid?
  end

  test 'adjustment can be -ve' do
    @adjustment.adjustment = -1
    assert @adjustment.valid?
  end

  test 'associated purchase must be valid' do
    @adjustment.purchase_id = 21
    refute @adjustment.valid?
  end
end
