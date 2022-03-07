require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  def setup
    @product = Product.new(max_classes: 10,
                           validity_length: 3,
                           validity_unit: 'M',
                           workout_group_id: ActiveRecord::FixtureSet.identify(:space))
  end

  test 'should be valid' do
    assert @product.valid?
  end

  test 'max_classes should be present' do
    @product.max_classes = '     '
    refute @product.valid?
  end

  test 'validity_length should be present' do
    @product.validity_length = '     '
    refute @product.valid?
  end

  test 'validity_unit should be present' do
    @product.validity_unit = '     '
    refute @product.valid?
  end

  test 'product should be unique' do
    duplicate_product = @product.dup
    @product.save
    refute duplicate_product.valid?
  end

  test 'similar product for different workout group should be valid' do
    similar_product = @product.dup
    similar_product.workout_group_id = ActiveRecord::FixtureSet.identify(:pilates)
    @product.save
    assert similar_product.valid?
  end
end
