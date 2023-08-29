require 'test_helper'

class PriceTest < ActiveSupport::TestCase
  def setup
    @product = products(:unlimited3m)
    @price = Price.new(price: 20_000,
                       date_from: '2022-01-01',
                       date_until: '2122-01-01',
                       product_id: @product.id)
    @price_Uc3mbase = prices(:Uc3mbase)
    #  scope testing https://dev.to/konnorrogers/testing-scopes-with-rails-4ho9
    @price1 = Price.create!(price: 20_000, date_from: '2022-01-01', date_until: '2122-12-31', product_id: @product.id)
    @price1a = Price.create!(price: 21_000, date_from: '2022-06-01', date_until: '2022-12-31', product_id: @product.id)
    @price2 = Price.create!(price: 22_000, date_from: '2023-01-01', date_until: '2023-12-31', product_id: @product.id)
    @price3 = Price.create!(price: 25_000, date_from: '2024-01-01', date_until: '2124-12-31', product_id: @product.id)
    @prices = Price.where(id: [@price1.id, @price1a.id, @price2.id, @price3.id])
  end

  test 'should be valid' do
    assert_predicate @price, :valid?
  end

  test 'date_from should not be blank' do
    @price.date_from = '     '

    refute_predicate @price, :valid?
  end

  test 'date_until should not be blank' do
    @price.date_from = '     '

    refute_predicate @price, :valid?
  end

  test 'product should be valid' do
    @price.product_id = 4000

    refute_predicate @price, :valid?
  end

  test 'base_at scope' do
    assert_equal @prices.base_at(Date.parse('2022-01-01')).first, @price1
    assert_equal @prices.base_at(Date.parse('2022-12-31')).first, @price1a
    assert_equal @prices.base_at(Date.parse('2023-06-30')).first, @price2
    assert_equal @prices.base_at(Date.parse('2024-06-30')).first, @price3
  end

  test '#deletable?' do
    refute @price_Uc3mbase.deletable? # as it has 2 associated purchases
    Purchase.where(price_id: @price_Uc3mbase.id).destroy_all
    assert @price_Uc3mbase.deletable?
  end  
end
