require 'test_helper'

class PriceTest < ActiveSupport::TestCase
  def setup
    @price = Price.new(name: 'base',
                       price: 1000,
                       date_from: '2022-01-01',
                       current: true,
                       product_id: products(:unlimited3m).id)
  end

  test 'should be valid' do
    assert_predicate @price, :valid?
  end

  # post Oct 22, price is calculated based on base and discount
  # test 'price should be present' do
  #   @price.price = '     '
  #   refute_predicate @price, :valid?
  # end

  # test 'price should be integer' do
  #   @price.price = 'cheap'
  #   refute_predicate @price, :valid?
  # end

  test 'name should be present' do
    @price.name = '     '
    refute_predicate @price, :valid?
  end

  test 'date_from should not be blank' do
    @price.date_from = '     '
    refute_predicate @price, :valid?
  end

  test 'product should be valid' do
    @price.product_id = 4000
    refute_predicate @price, :valid?
  end
end
