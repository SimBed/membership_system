require 'test_helper'
class PurchaseTest < ActiveSupport::TestCase
  def setup
    @purchase =
      Purchase.new(client_id: ActiveRecord::FixtureSet.identify(:aparna),
                   product_id: ActiveRecord::FixtureSet.identify(:unlimited3m),
                   payment: 10_000, dop: '2022-02-15', payment_mode: 'Cash',
                   # invoice: '', note: '', adjust_restart: false, ar_payment: '', ar_date: '',
                   # expired: false, fitternity_id: nil,
                   price_id: ActiveRecord::FixtureSet.identify(:one))
    @fitternity = ActiveRecord::FixtureSet.identify(:one)
  end

  test 'should be valid' do
    assert @purchase.valid?
  end

  test 'payment should be present' do
    @purchase.payment = '     '
    refute @purchase.valid?
  end

  test 'invoice should not be too short' do
    @purchase.invoice = 'a' * 4
    refute @purchase.valid?
  end

  test 'invoice should be unique' do
    @purchase.invoice = 'a' * 6
    @duplicate_purchase = @purchase.dup
    @purchase.save
    refute @duplicate_purchase.valid?
  end

  test 'associated fitternity (if there is one) should exist' do
    @purchase.fitternity_id = 21
    refute @purchase.valid?
  end

  test 'if payment_method is Fitternity then a Fitternity should be ongoing' do
    @purchase.payment_mode = 'Fitternity'
    Fitternity.find(@fitternity).update(max_classes: 0)
    refute @purchase.valid?
  end

  test 'if A&R then A&R date should be present' do
    @purchase.adjust_restart = true
    @purchase.ar_payment = 1000
    refute @purchase.valid?
  end

  test 'if A&R then A&R payment should be present' do
    @purchase.adjust_restart = true
    @purchase.ar_date = '2022-02-01'
    refute @purchase.valid?
  end
end
