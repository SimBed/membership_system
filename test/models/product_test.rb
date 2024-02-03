require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  def setup
    @product = Product.new(max_classes: 10,
                           validity_length: 3,
                           validity_unit: 'M',
                           color: 'none',
                           workout_group_id: workout_groups(:space).id)
    @product_without_purchase = products(:spaceothers)
    @client = clients(:aparna)
  end

  test 'should be valid' do
    assert_predicate @product, :valid?
  end

  test 'max_classes should be present' do
    @product.max_classes = '     '

    refute_predicate @product, :valid?
  end

  test 'validity_length should be present' do
    @product.validity_length = '     '

    refute_predicate @product, :valid?
  end

  test 'validity_unit should be present' do
    @product.validity_unit = '     '

    refute_predicate @product, :valid?
  end

  # reinstate when product_combo_must_be_unique validation corrected
  # test 'product should be unique' do
  #   duplicate_product = @product.dup
  #   @product.save

  #   refute_predicate duplicate_product, :valid?
  # end

  test 'similar product for different workout group should be valid' do
    similar_product = @product.dup
    similar_product.workout_group_id = workout_groups(:pilates).id
    @product.save

    assert_predicate similar_product, :valid?
  end

  test '#deletable?' do
    refute @product_without_purchase.deletable? # as it has a price
    price = @product_without_purchase.base_price_at(Time.zone.now)
    Purchase.create(client_id: @client.id,
                    product_id: @product_without_purchase.id,
                    payment: price.price, dop: '2022-02-15', payment_mode: 'Cash',
                    price_id: price.id,
                    purchase_id: nil)
    price.destroy

    refute @product_without_purchase.deletable?
    Purchase.last.destroy

    assert @product_without_purchase.deletable?
  end
end
