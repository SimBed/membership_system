require 'test_helper'
class PurchaseTest < ActiveSupport::TestCase
  def setup
    travel_to Date.parse('18 March 2022')
    @client = clients(:aparna)
    @client2 = clients(:bhavik)
    @product = products(:unlimited3m)
    @price = prices(:Uc3mbase)
    @purchase =
      Purchase.new(client_id: @client.id,
                   product_id: @product.id,
                   payment: 10_000, dop: '2022-02-15', payment_mode: 'Cash',
                   price_id: @price.id,
                   purchase_id: nil)
    @purchase_package = purchases(:AnushkaUC3Mong)
    @purchase_dropin = purchases(:priya1c1d)
    @purchase_dropin2 = purchases(:kiran1c1d_notstarted)
    @purchase_fixed = purchases(:tina8c5wong)
    @purchase_trial = purchases(:purchase_trial)
    @purchase_with_freeze = purchases(:purchase_with_freeze) # freeze 10/1/22 - 28/3/22
    @purchase_pt = purchases(:purchase_12C5WPT)
    @purchase_ptrider = purchases(:purchase_ptrider)
    @purchase_main = @purchase_ptrider.main_purchase # purchase_12C5WPT
    @wkclass1 = wkclasses(:hiitfeb26)
    @wkclass_already_attended = wkclasses(:wkclass362)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    # @price_fitternity = prices(:price2)
    # @fitternity = fitternities(:two_ongoing)
  end

  test 'should be valid' do
    assert_predicate @purchase, :valid?
  end

  test 'payment should be present' do
    @purchase.payment = '     '

    refute_predicate @purchase, :valid?
  end

  test 'invoice should not be too short' do
    @purchase.invoice = 'a' * 4

    refute_predicate @purchase, :valid?
  end

  test 'invoice does not need to be unique' do
    @purchase.invoice = 'a' * 6
    @duplicate_purchase = @purchase.dup
    @purchase.save

    assert_predicate @duplicate_purchase, :valid?
  end

  test 'if A&R then A&R date should be present' do
    @purchase.adjust_restart = true
    @purchase.ar_payment = 1000

    refute_predicate @purchase, :valid?
  end

  test 'if A&R then A&R payment should be present' do
    @purchase.adjust_restart = true
    @purchase.ar_date = '2022-02-01'

    refute_predicate @purchase, :valid?
  end

  test 'delegated name method' do
    assert_equal 'Group UC:3M', @purchase_package.name
    assert_equal 'Group 1C:1D', @purchase_dropin.name
    assert_equal 'Pilates 8C:5W', @purchase_fixed.name
  end

  test 'delegated formal_name method' do
    assert_equal 'Group - Unlimited Classes 3 Months', @purchase_package.formal_name
    assert_equal 'Group - 1 Class 1 Day', @purchase_dropin.formal_name
    assert_equal 'Pilates - 8 Classes 5 Weeks', @purchase_fixed.formal_name
  end

  test 'delegated dropin? method' do
    refute_predicate @purchase_package, :dropin?
    assert_predicate @purchase_dropin, :dropin?
    refute_predicate @purchase_fixed, :dropin?
    refute_predicate @purchase_trial, :dropin?
  end

  test 'delegated trial? method' do
    refute_predicate @purchase_package, :trial?
    refute_predicate @purchase_dropin, :trial?
    refute_predicate @purchase_fixed, :trial?
    assert_predicate @purchase_trial, :trial?
  end

  test 'delegated unlimited_package? method' do
    assert_predicate @purchase_package, :unlimited_package?
    refute_predicate @purchase_dropin, :unlimited_package?
    refute_predicate @purchase_fixed, :unlimited_package?
    refute_predicate @purchase_trial, :unlimited_package?
  end

  test 'delegated fixed_package? method' do
    refute_predicate @purchase_package, :fixed_package?
    refute_predicate @purchase_dropin, :fixed_package?
    assert_predicate @purchase_fixed, :fixed_package?
    refute_predicate @purchase_trial, :fixed_package?
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

  # test 'revenue_for_class method' do
  #   assert_equal 12_750 / 60, @purchase_package.revenue_for_class(@purchase_package.attendances.first.wkclass)
  #   assert_equal 0, @purchase_dropin.revenue_for_class(@wkclass1)
  #   assert_equal 6000 / 8, @purchase_fixed.revenue_for_class(@purchase_fixed.attendances.last.wkclass)
  # end

  test 'qualifying_for method' do
    assert_equal [374, 201, 212, 4, 335, 312, 368, 229, 200, 441, 99, 198, 120, 224, 360, 125, 341, 119, 90],
                 Purchase.qualifying_for(@wkclass1).pluck(:id)
  end
  # 90 are frozen, but correctly still appears

  test 'available_for_booking method' do
    assert_equal [4], Purchase.available_for_booking(@wkclass1, @client2).pluck(:id)
  end

  test 'use_for_booking method' do
    # expiry date of @client's purchase (2022-03-22) is before wkclass date
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)

    assert_nil Purchase.use_for_booking(@tomorrows_class_early, @client)
    assert_equal 4, Purchase.use_for_booking(@tomorrows_class_early, @client2).id
  end

  test 'committed_on? method' do
    assert @purchase_package.committed_on? Date.parse('22 Feb 2022')
    refute @purchase_package.committed_on? @wkclass1.start_time
  end

  test 'already_used_for? method' do
    assert @purchase_package.already_used_for? @wkclass_already_attended
    refute @purchase_package.already_used_for? @wkclass1
  end

  test 'purchased_after? method' do
    assert @purchase_package.purchased_after? Date.parse('23 Jan 2022')
    refute @purchase_package.purchased_after? @wkclass1.start_time
  end

  test 'name_with_dop method' do
    assert_equal 'Group UC:3M - 24 Jan 22', @purchase_package.name_with_dop
    assert_equal 'Group 1C:1D - 26 Feb 22', @purchase_dropin.name_with_dop
    assert_equal 'Pilates 8C:5W - 15 Feb 22', @purchase_fixed.name_with_dop
  end

  test 'status_calc method' do
    assert_equal 'ongoing', @purchase_package.status_calc
    assert_equal 'expired', @purchase_dropin.status_calc
    assert_equal 'not started', @purchase_dropin2.status_calc
    assert_equal 'ongoing', @purchase_fixed.status_calc
    travel_to Date.parse('1 February 2022') # expiry date of @purchase_pt is 8/2/2022
    assert_equal 'ongoing', @purchase_pt.status_calc
    assert_equal 'not started', @purchase_ptrider.status_calc
    @purchase_pt.update(status: 'expired') # once main is expired, rider must be expired
    assert_equal 'expired', @purchase_ptrider.reload.status_calc
  end

  test 'freezed? method' do
    # testing on eg Date.parse('10 Jan 2022') is not good enough as the limit of the day is 24 hours later
    refute @purchase_with_freeze.freezed? '9 Jan 2022 10:30'.to_datetime
    assert @purchase_with_freeze.freezed? '10 Jan 2022 10:30'.to_datetime
    assert @purchase_with_freeze.freezed? '28 March 2022 10:30'.to_datetime
    refute @purchase_with_freeze.freezed? '29 March 2022 10:30'.to_datetime
  end

  test 'freezes_cover method' do
    assert_empty @purchase_with_freeze.freezes_cover('9 Jan 2022 10:30'.to_datetime).pluck(:id)
    assert_equal [48], @purchase_with_freeze.freezes_cover('10 Jan 2022 10:30'.to_datetime).pluck(:id)
    assert_equal [48], @purchase_with_freeze.freezes_cover('28 March 2022 10:30'.to_datetime).pluck(:id)
    assert_empty @purchase_with_freeze.freezes_cover('29 March 2022 10:30'.to_datetime).pluck(:id)
  end

  test 'expired_in? method' do
    refute @purchase_package.expired_in? month_period('Mar 2022')
    assert @purchase_dropin.expired_in? month_period('Feb 2022')
    refute @purchase_dropin2.expired_in? month_period('Feb 2022')
    refute @purchase_fixed.expired_in? month_period('Mar 2022')
  end

  test 'expiry_cause method' do
    assert_nil @purchase_package.expiry_cause
    assert_equal 'used max classes', @purchase_dropin.expiry_cause
    assert_nil @purchase_dropin2.expiry_cause
    assert_nil @purchase_fixed.expiry_cause
  end

  test 'expired_on method' do
    assert_nil @purchase_package.expired_on
    assert_equal '25 Feb 22', @purchase_dropin.expired_on.strftime('%d %b %y')
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
    assert_equal Date.parse('25 Feb 2022'), @purchase_dropin.expiry_date_calc
    assert_nil @purchase_dropin2.expiry_date_calc
    assert_equal Date.parse('21 Mar 2022'), @purchase_fixed.expiry_date_calc
  end

  test 'days_to_expiry method' do
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
    assert_equal '25 Jan 22 - 27 Apr 22', @purchase_package.start_to_expiry
    assert_equal '25 Feb 22', @purchase_dropin.start_to_expiry
    assert_equal 'not started', @purchase_dropin2.start_to_expiry
    assert_equal '15 Feb 22 - 25 Mar 22', @purchase_fixed.start_to_expiry
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
    refute_predicate @purchase_package, :close_to_expiry?
    assert_predicate @purchase_dropin, :close_to_expiry?
    assert_predicate @purchase_dropin2, :close_to_expiry?
    refute_predicate @purchase_fixed, :close_to_expiry?
  end

  test 'deletable? method' do
    @purchase.save

    assert @purchase.deletable?
    refute @purchase_with_freeze.deletable?
    refute @purchase_package.deletable?
  end

  test '#sunset_date_calc' do
    assert_equal Date.parse('21 Oct 2022'), @purchase_package.sunset_date_calc # dop 2022-01-24, 3M
    assert_equal Date.parse('30 Mar 2022'), @purchase_dropin.sunset_date_calc # dop 2022-02-26, 1D
    assert_equal Date.parse('18 Sep 2022'), @purchase_fixed.sunset_date_calc # dop 2022-02-15, 5W
    assert_equal Date.parse('4 April 2022'), @purchase_trial.sunset_date_calc # dop 2022-02-25, 1W
    assert_equal Date.parse('8 Aug 2022'), @purchase_with_freeze.sunset_date_calc # dop 2021-11-09, 3M (freeze 2022-01-10 - 2022-03-28)
  end

  test 'unexpired_rider_without_ongoing_main scope' do
    assert 'not started', @purchase_ptrider.status
    assert 'ongoing', @purchase_main.status
    @purchases = Purchase.where(id: [@purchase_ptrider.id, @purchase_main.id])
    assert_equal @purchases.unexpired_rider_without_ongoing_main, []
    @purchase_main.update(status: 'not_started')
    assert_equal @purchases.unexpired_rider_without_ongoing_main, [@purchase_ptrider]
    @purchase_main.update(status: 'expired')
    assert_equal @purchases.unexpired_rider_without_ongoing_main, [@purchase_ptrider]
  end

  # test 'associated fitternity (if there is one) should exist' do
  #   @purchase.fitternity_id = 21
  #   refute_predicate @purchase, :valid?
  # end

  # test 'if payment_method is Fitternity then a Fitternity should be ongoing' do
  #   @purchase.payment_mode = 'Fitternity'
  #   @fitternity.update(max_classes: @fitternity.purchases.size)
  #   refute_predicate @purchase, :valid?
  # end

  # test 'A Fitternity price must have a Fitternity payment mode' do
  #   @purchase.price = @price_fitternity
  #   refute_predicate @purchase, :valid?
  # end

  # test 'A price that is not Fitternity can not have a Fitternity payment mode' do
  #   @purchase.payment_mode = 'Fitternity'
  #   refute_predicate @purchase, :valid?
  # end
end
