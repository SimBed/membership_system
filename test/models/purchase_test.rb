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
    @fitternity = fitternities(:one)
    @purchase_package = purchases(:aparna_package)
    @purchase_dropin = purchases(:aparna_dropin)
    @purchase_fixed = purchases(:namrata_fixed)
    @wkclass1 = wkclasses(:one)
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
    @fitternity.update(max_classes: 0)
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

  test 'delegated name method' do
    assert_equal 'Space UC:3M', @purchase_package.name
    assert_equal 'Space 1C:1D', @purchase_dropin.name
    assert_equal 'Pilates 8C:5W', @purchase_fixed.name
  end

  test 'delegated dropin? method' do
    refute @purchase_package.dropin?
    assert @purchase_dropin.dropin?
    refute @purchase_fixed.dropin?
  end

  test 'attendance_estimate method' do
    assert_equal 60, @purchase_package.attendance_estimate
    assert_equal 1, @purchase_dropin.attendance_estimate
    assert_equal 8, @purchase_fixed.attendance_estimate
  end

  test 'delegated revenue_for_class method' do
    assert_equal 10000 / 60, @purchase_package.revenue_for_class(@wkclass1)
    assert_equal 0, @purchase_dropin.revenue_for_class(@wkclass1)
    assert_equal 9000 / 8, @purchase_fixed.revenue_for_class(@wkclass1)
  end

end
