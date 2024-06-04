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
                   charge: 10_000, dop: '2022-02-15', payment_mode: 'Cash',
                   price_id: @price.id,
                   purchase_id: nil,
                   payment_attributes: {amount: 10000, payment_mode: 'credit-card'})
    @purchase_package = purchases(:AnushkaUC3Mong)
    @purchase_dropin = purchases(:priya1c1d)
    @purchase_dropin2 = purchases(:kiran1c1d_notstarted)
    @purchase_fixed = purchases(:tina8c5wong)
    @purchase_trial = purchases(:purchase_trial)
    @purchase_with_freezes = purchases(:purchase_with_freezes) # freeze 10/1/22 - 28/3/22
    @purchase_pt = purchases(:purchase_12C5WPT)
    @purchase_ptrider = purchases(:purchase_ptrider)
    @purchase_main = @purchase_ptrider.main_purchase # purchase_12C5WPT
    @wkclass1 = wkclasses(:hiitfeb26)
    @wkclass_already_attended = wkclasses(:wkclass362)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    @product_without_rider = products(:unlimited3m)
    @product_with_rider = products(:product_12C5WPT)
  end

  test 'should be valid' do
    assert_predicate @purchase, :valid?
  end

  test 'charge should be present' do
    @purchase.charge = '     '

    refute_predicate @purchase, :valid?
  end

  test 'inconsistent rider not valid' do
    @purchase_pt.product = @product_without_rider
    refute_predicate @purchase_pt, :valid?  

    @purchase_package.product = @product_with_rider
    refute_predicate @purchase_package, :valid?  
  end

  test 'changing client of rider or riders main purchase not valid' do
    @purchase_pt.client =  @client2
    refute_predicate @purchase_pt, :valid?  

    @purchase_package.client =  @client2
    refute_predicate @purchase_package, :valid?  
  end


  test 'delegated name method' do
    assert_equal 'Group UC:3M', @purchase_package.name
    assert_equal 'Group 1C:1D', @purchase_dropin.name
    assert_equal 'Pilates 8C:5W', @purchase_fixed.name
    assert_equal 'Group - Unlimited Classes 3 Months', @purchase_package.name(verbose: true)
    assert_equal 'Group - 1 Class 1 Day', @purchase_dropin.name(verbose: true)
    assert_equal 'Pilates - 8 Classes 5 Weeks', @purchase_fixed.name(verbose: true)
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

  test 'available_for_booking method (no client)' do
    assert_equal [purchases(:purchase_374), purchases(:AnushkaUC3Mong), purchases(:AparnaUC1Mong), purchases(:purchase_212), @purchase_with_freezes, purchases(:purchase_335), purchases(:purchase_312),
                  @purchase_trial, @purchase_dropin2, purchases(:purchase_200), @purchase_ptrider, purchases(:purchase_99), purchases(:purchase_198), purchases(:purchase_120), purchases(:purchase_224),
                  purchases(:purchase_360), purchases(:purchase_125), purchases(:purchase_341), purchases(:purchase_119), purchases(:purchase_90)],
                 Purchase.available_for_booking(@wkclass1)
    # assert_equal [374, 201, 212, 4, 335, 312, 368, 229, 200, 441, 99, 198, 120, 224, 360, 125, 341, 119, 90],
    #              Purchase.available_for_booking(@wkclass1).pluck(:id)
  end
  # 90 are frozen, but correctly still appears

  test 'available_for_booking method (with client)' do
    assert_equal [@purchase_with_freezes], Purchase.available_for_booking(@wkclass1, @client2)
  end

  test 'available_for_booking method (with client and not restricted i. for waiting list purposes)' do
    assert_equal [@purchase_with_freezes], Purchase.available_for_booking(@wkclass1, @client2, restricted: false)
  end

  test 'use_for_booking method' do
    # expiry date of @client's purchase (2022-03-22) is before wkclass date
    travel_to(@tomorrows_class_early.start_time.beginning_of_day)

    assert_nil Purchase.use_for_booking(@tomorrows_class_early, @client)
    assert_equal @purchase_with_freezes, Purchase.use_for_booking(@tomorrows_class_early, @client2)
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
    refute @purchase_with_freezes.freezed? '9 Jan 2022 10:30'.to_datetime
    assert @purchase_with_freezes.freezed? '10 Jan 2022 10:30'.to_datetime
    assert @purchase_with_freezes.freezed? '28 March 2022 10:30'.to_datetime
    refute @purchase_with_freezes.freezed? '29 March 2022 10:30'.to_datetime
  end

  test 'freezes_cover method' do
    assert_empty @purchase_with_freezes.freezes_cover('9 Jan 2022 10:30'.to_datetime)
    assert_equal [freezes(:another_freeze)], @purchase_with_freezes.freezes_cover('10 Jan 2022 10:30'.to_datetime)
    assert_equal [freezes(:another_freeze)], @purchase_with_freezes.freezes_cover('28 March 2022 10:30'.to_datetime)
    assert_empty @purchase_with_freezes.freezes_cover('29 March 2022 10:30'.to_datetime)
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
    refute @purchase_with_freezes.deletable?
    refute @purchase_package.deletable?
  end

  test '#sunset_date_calc' do
    assert_equal Date.parse('21 Oct 2022'), @purchase_package.sunset_date_calc # dop 2022-01-24, 3M
    assert_equal Date.parse('30 Mar 2022'), @purchase_dropin.sunset_date_calc # dop 2022-02-26, 1D
    assert_equal Date.parse('18 Sep 2022'), @purchase_fixed.sunset_date_calc # dop 2022-02-15, 5W
    assert_equal Date.parse('4 April 2022'), @purchase_trial.sunset_date_calc # dop 2022-02-25, 1W
    assert_equal Date.parse('8 Aug 2022'), @purchase_with_freezes.sunset_date_calc # dop 2021-11-09, 3M (freeze 2022-01-10 - 2022-03-28)
  end

  test 'unexpired_rider_without_ongoing_main scope' do
    assert_equal 'not started', @purchase_ptrider.status
    assert_equal 'ongoing', @purchase_main.status
    @purchases = Purchase.where(id: [@purchase_ptrider.id, @purchase_main.id])

    assert_empty(@purchases.unexpired_rider_without_ongoing_main)
    @purchase_main.update(status: 'not_started')

    assert_equal @purchases.unexpired_rider_without_ongoing_main, [@purchase_ptrider]
    @purchase_main.update(status: 'expired')

    assert_equal @purchases.unexpired_rider_without_ongoing_main, [@purchase_ptrider]
  end

  test '#restart_payment' do
    travel_to Date.parse('10 Jan 2024')  # discount system has not been implemented into test fixture so price data is still based around a price rather than base price * discount. I've retired old prices like ClassPass
    # from 1/1/2023 (which should now be base_price X clsspass discount. Before doing this Product.current.dropin.space_group.first.base_price_at(Time.zone.now) might pickup the wrong dropin price
    assert_equal 1000, Product.current.dropin.space_group.first.base_price_at(Time.zone.now).price
    assert_equal 5000, @purchase_package.restart_payment
    assert_equal 6000, @purchase_fixed.restart_payment
    assert_equal 1500, @purchase_with_freezes.restart_payment
  end

  test '#can_restart?' do
    travel_to Date.parse('10 Jan 2024')
    assert_equal 1000, Product.current.dropin.space_group.first.base_price_at(Time.zone.now).price    
    assert @purchase_package.can_restart?
    refute @purchase_dropin.can_restart?
    assert @purchase_fixed.can_restart?
    refute @purchase_trial.can_restart?
    # re-establish this as a refute with explanation 'not because frozen, but becasue restart payment > purchase charge' (as it was before I started to remove ids and lost association to attendances)
    # add some attendances to @purchase_with_freezes
    assert @purchase_with_freezes.can_restart? 
    @purchase_with_freezes.update(charge: 100000)
    assert @purchase_with_freezes.can_restart?
    refute @purchase_pt.can_restart?
    refute @purchase_ptrider.can_restart?
    Restart.create(parent_id: @purchase_package.id) # Restart the package
    refute @purchase_package.reload.can_restart? # cant restart the same purchase more than once
  end

  test '#new_freeze_dates' do
    # already travelled to 18/3/2022
    # no freeze
    assert_equal({ earliest: Date.parse('19 Mar 2022'), latest: Date.parse('18 Apr 2022') }, @purchase_package.new_freeze_dates)
    # currently frozen until 28/3/22 (expiry date 6/May 2022)
    assert_equal({ earliest: Date.parse('29 Mar 2022'), latest: Date.parse('18 Apr 2022') }, @purchase_with_freezes.new_freeze_dates)
    # currently not frozen, a purchased freeze, which has not yet started will end after more than a month from now
    @purchase_package.freezes.create(start_date: Date.parse('15 April 2022'), end_date: Date.parse('29 April 2022'))
    # puts @purchase_package.expiry_date
    ApplicationController.new().update_purchase_status([@purchase_package])
    # puts @purchase_package.expiry_date
    assert_equal({ earliest: Date.parse('19 Mar 2022'), latest: Date.parse('14 Apr 2022') }, @purchase_package.new_freeze_dates)
    Freeze.last.destroy
    # package frozen now and for the next month
    @purchase_package.freezes.create(start_date: Date.parse('15 March 2022'), end_date: Date.parse('29 April 2022'))
    ApplicationController.new().update_purchase_status([@purchase_package])
    assert_equal({ earliest: nil, latest: nil }, @purchase_package.new_freeze_dates)
  end

end
