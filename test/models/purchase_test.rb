require 'test_helper'
class PurchaseTest < ActiveSupport::TestCase
  def setup
    travel_to Date.parse('18 March 2022')

    @purchase =
      Purchase.new(client_id: clients(:aparna).id,
                   product_id: products(:unlimited3m).id,
                   payment: 10_000, dop: '2022-02-15', payment_mode: 'Cash',
                   # invoice: '', note: '', adjust_restart: false, ar_payment: '', ar_date: '',
                   # expired: false, fitternity_id: nil,
                   price_id: prices(:base_new_unlimited3m).id)
    @fitternity = fitternities(:two_ongoing)
    @purchase_package = purchases(:AnushkaUC3Mong)
    @purchase_dropin = purchases(:priya1c1d)
    @purchase_dropin2 = purchases(:kiran1c1d_notstarted)
    @purchase_fixed = purchases(:tina8c5wong)
    @wkclass1 = wkclasses(:hiitfeb26)
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
    @fitternity.update(max_classes: @fitternity.purchases.size)
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
    assert_equal 'Space Group UC:3M', @purchase_package.name
    assert_equal 'Space Group 1C:1D', @purchase_dropin.name
    assert_equal 'Pilates 8C:5W', @purchase_fixed.name
  end

  test 'delegated dropin? method' do
    refute @purchase_package.dropin?
    assert @purchase_dropin.dropin?
    refute @purchase_fixed.dropin?
  end

  test 'delegated max_classes method' do
    assert_equal 1000, @purchase_package.max_classes
    assert_equal 1, @purchase_dropin.max_classes
    assert_equal 8, @purchase_fixed.max_classes
  end

  test 'attendance_estimate method' do
    assert_equal 60, @purchase_package.attendance_estimate
    assert_equal 1, @purchase_dropin.attendance_estimate
    assert_equal 8, @purchase_fixed.attendance_estimate
  end

  test 'revenue_for_class method' do
    assert_equal 12750 / 60, @purchase_package.revenue_for_class(@purchase_package.attendances.first.wkclass)
    assert_equal 0, @purchase_dropin.revenue_for_class(@wkclass1)
    assert_equal 6000 / 8, @purchase_fixed.revenue_for_class(@purchase_fixed.attendances.last.wkclass)
  end

  test 'self.qualifying_for(wkclass)' do
    assert_equal [441, 374, 201, 212, 335, 459, 381, 406, 229, 438, 382, 200, 407, 377, 99, 198, 389, 399, 120,
                  224, 360, 125, 341, 119, 390, 416], Purchase.qualifying_for(@wkclass1).pluck(:id)
  end

  test 'name_with_dop method' do
    assert_equal 'Space Group UC:3M - 24 Jan 22', @purchase_package.name_with_dop
    assert_equal 'Space Group 1C:1D - 26 Feb 22', @purchase_dropin.name_with_dop
    assert_equal 'Pilates 8C:5W - 15 Feb 22', @purchase_fixed.name_with_dop
  end

  test 'status_calc method' do
    assert_equal 'ongoing', @purchase_package.status_calc
    assert_equal 'expired', @purchase_dropin.status_calc
    assert_equal 'not started', @purchase_dropin2.status_calc
    assert_equal 'ongoing', @purchase_fixed.status_calc
  end

  test 'freezed? method' do
    refute @purchase_package.freezed?(Date.today)
    refute @purchase_dropin.freezed?(Date.today)
    refute @purchase_dropin2.freezed?(Date.today)
    refute @purchase_fixed.freezed?(Date.today)
  end

  test 'expired_in? method' do
    refute @purchase_package.expired_in?('Mar 2022')
    assert @purchase_dropin.expired_in?('Feb 2022')
    refute @purchase_dropin2.expired_in?('Feb 2022')
    refute @purchase_fixed.expired_in?('Mar 2022')
  end

  test 'expiry_cause method' do
    assert_nil @purchase_package.expiry_cause
    assert_equal 'used max classes', @purchase_dropin.expiry_cause
    assert_nil @purchase_dropin2.expiry_cause
    assert_nil @purchase_fixed.expiry_cause
  end

  test 'expired_on method' do
    assert_nil @purchase_package.expired_on
    assert_equal '25 Feb 22', @purchase_dropin.expired_on
    assert_nil @purchase_dropin2.expired_on
    assert_nil @purchase_fixed.expired_on
  end

  test 'will_expire_on method' do
    assert_nil @purchase_package.will_expire_on
    assert_nil @purchase_dropin.will_expire_on
    assert_nil @purchase_dropin2.will_expire_on
    assert_nil @purchase_fixed.will_expire_on
  end

  test 'expiry_date_calc method' do
    assert_equal Date.parse('25 Apr 2022'), @purchase_package.expiry_date_calc
    assert_equal Date.parse('19 Mar 2022'), @purchase_dropin.expiry_date_calc
    assert_equal 'n/a', @purchase_dropin2.expiry_date_calc
    assert_equal Date.parse('21 Mar 2022'), @purchase_fixed.expiry_date_calc
  end

  # tests based on Date.today need improvement (an environment variable perhaps)
  test 'days_to_expiry method' do
    # test data is based on attendance in the 2030s ie first class is in 2030 and expiry date based on that
    assert_equal 40, @purchase_package.days_to_expiry
    assert_equal 1000, @purchase_dropin.days_to_expiry
    assert_equal 1000, @purchase_dropin2.days_to_expiry
    # assert_operator 1000, :<, @purchase_fixed.days_to_expiry
    assert_equal 7, @purchase_fixed.days_to_expiry
  end

  # needs a proper testcase
  test 'expiry_revenue method' do
    assert_equal 0, @purchase_package.expiry_revenue
    assert_equal 0, @purchase_dropin.expiry_revenue
    assert_equal 0, @purchase_dropin2.expiry_revenue
    assert_equal 0, @purchase_fixed.expiry_revenue
  end

  test 'start_to_expiry method' do
    assert_equal "25 Jan 22 - 27 Apr 22", @purchase_package.start_to_expiry
    assert_equal "25 Feb 22 - 25 Feb 22", @purchase_dropin.start_to_expiry
    assert_equal "not started", @purchase_dropin2.start_to_expiry
    assert_equal "15 Feb 22 - 25 Mar 22", @purchase_fixed.start_to_expiry
  end

  test 'attendances_remain method' do
    assert_equal 'unlimited', @purchase_package.attendances_remain(provisional: true, unlimited_text: true)
    assert_equal 0, @purchase_dropin.attendances_remain(provisional: true, unlimited_text: true)
    assert_equal 1, @purchase_dropin2.attendances_remain(provisional: true, unlimited_text: true)
    assert_equal 2, @purchase_fixed.attendances_remain(provisional: true, unlimited_text: true)
    assert_equal 995, @purchase_package.attendances_remain(provisional: true, unlimited_text: false)
    assert_equal 995, @purchase_package.attendances_remain(provisional: false, unlimited_text: false)
  end

  test 'close_to_expiry? method' do
    refute @purchase_package.close_to_expiry?
    assert @purchase_dropin.close_to_expiry?
    assert @purchase_dropin2.close_to_expiry?
    refute @purchase_fixed.close_to_expiry?
  end

end
