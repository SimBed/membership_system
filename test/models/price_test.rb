require 'test_helper'

class PriceTest < ActiveSupport::TestCase
  def setup
    @price = Price.new(name: 'base',
                       price: 1000,
                       date_from: '2022-01-01',
                       current: true,
                       product_id: ActiveRecord::FixtureSet.identify(:unlimited3m))
  end

  test 'should be valid' do
    assert @price.valid?
  end

  test 'price should be present' do
    @price.price = '     '
    refute @price.valid?
  end

  test 'price should be integer' do
    @price.price = 'cheap'
    refute @price.valid?
  end

  test 'name should be present' do
    @price.name = '     '
    refute @price.valid?
  end
end
