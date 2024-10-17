require 'test_helper'

class ClientRenewalTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @account_client_for_ongoing_trial = accounts(:client_for_ongoing_trial)
    @account_client_for_expired_trial = accounts(:client_for_expired_trial)
    @account_new_client = accounts(:client_no_purchases)
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
    @product_unlimited1m = products(:unlimited1m)
    @product_unlimited3m = products(:unlimited3m)
    @product_trial = products(:trial)
    @price_uc1m_base = prices(:Uc1mbase)
    @price_uc3m_base = prices(:Uc3mbase)
    @price_trial = prices(:trial)
    @discount_trialbeforeexpiry = discounts(:trialbeforeexpiry)
    @discount_trialafterexpiry = discounts(:trialafterexpiry)
    @discount_beforeexpiry = discounts(:beforeexpiry)
    @discount_firstpackage = discounts(:firstpackage)
  end

  test 'renewal form appears correctly on booking page for client with ongoing package (with 59 days to go) and responds to settings' do
    log_in_as(@account_client)
    follow_redirect!

    assert_template 'client/bookings/index'
    # puts @response.parsed_body
    # 1 form for razorpay
    assert_select 'form'
    assert_select 'div.discount-price', text: 'Rs. 24,250'

    Setting.enable_online_payment = false
    get client_bookings_path(@account_client.client)
    assert_select 'form', false

    Setting.enable_online_payment = true
    Setting.days_remain = 60
    get client_bookings_path(@account_client.client)
    assert_select 'form'

    Setting.days_remain = 58
    get client_bookings_path(@account_client.client)
    assert_select 'form', false
  end

  test 'renewal details correct for client with ongoing package' do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/bookings/index'
    assert_select 'div', text: 'Renew your Package before expiry with a 5% online discount!'
    assert_select 'div', text: 'Group - Unlimited Classes 3 Months'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 24,250'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='24250']"
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_beforeexpiry.id}']"
    # assert_select "input[type=hidden][name='status_discount_id']:not([value])"
    # assert_select "input[type=hidden][name='oneoff_discount_id']:not([value])"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client.id}']"
    # regexs = /data-amount="2425000"/
    # search_result = response.body.scan(regexs)

    # refute_empty search_result
  end

  test 'renewal details correct for client with expired package' do
    log_in_as(@account_client)
    # retire package
    purchase = @account_client.client.purchases.last
    # Unneccessarily engineered method of updating purchase
    # travel_to(purchase.expiry_date.advance(days:1))
    # purchase.update(status: purchase.status_calc)
    purchase.update_column(:status, 'expired')
    get client_bookings_path(@account_client.client)
    # puts @response.parsed_body
    assert_select 'div', text: 'Your Group Package has expired. Renew your Package now!'
    assert_select 'div', text: 'Group - Unlimited Classes 3 Months'
    assert_select 'div.base-price', false
    assert_select 'div.discount-price', text: 'Rs. 25,500'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='25500']"
    assert_select "input[type=hidden][name='discount_id']:not([value])"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client.id}']"
  end

  test 'renewal details correct for client with ongoing trial' do
    log_in_as(@account_client_for_ongoing_trial)
    follow_redirect!

    assert_template 'client/bookings/index'
    # puts @response.parsed_body
    assert_select 'div', text: 'Buy your first Package before your Trial expires with a 20% online discount!'
    assert_select 'div', text: 'Group - Unlimited Classes 3 Months'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 20,400'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='20400']"
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_trialbeforeexpiry.id}']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client_for_ongoing_trial.id}']"
  end

  test 'renewal details correct for client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    follow_redirect!

    assert_template 'client/bookings/index'
    assert_select 'div', text: 'Your Trial has expired. Buy your first Package with a 15% online discount!'
    assert_select 'div', text: 'Group - Unlimited Classes 3 Months'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 21,700'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='21700']"
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_trialafterexpiry.id}']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client_for_expired_trial.id}']"
  end

  test 'test shop items correct for client with ongoing package' do
    log_in_as(@account_client)
    get client_shop_path(@account_client.client)

    assert_template 'client/dynamic_pages/shop'
    assert_select 'h3', text: 'Renew your Package before expiry with a 5% online discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 9,050'
    # refute_empty response.body.scan(/data-amount="905000"/)
    assert_select 'li', text: 'Save Rs. 450'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 24,250'
    assert_select 'li', text: 'Save Rs. 1,250'
    # items in the razorpay form
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='9050']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='24250']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_beforeexpiry.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client.id}']", count: 2
  end

  test 'test shop items correct for client with expired package' do
    log_in_as(@account_client)
    # retire package
    purchase = @account_client.client.purchases.last
    purchase.update_column(:status, 'expired')
    get client_shop_path(@account_client.client)
    assert_template 'client/dynamic_pages/shop'
    assert_empty response.body.scan(/Renew your Package/)
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', text: ''
    assert_select 'div.discount-price', text: 'Rs. 9,500'
    assert_empty response.body.scan(/Save Rs./)
    assert_select 'div.discount-price', text: 'Rs. 25,500'
    # items in the razorpay form
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='9500']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='25500']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id']:not([value])", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client.id}']", count: 2
  end

  test 'test shop items correct for client with ongoing trial' do
    log_in_as(@account_client_for_ongoing_trial)
    get client_shop_path(@account_client_for_ongoing_trial.client)
    # File.write('test_output.html', response.body)
    assert_template 'client/dynamic_pages/shop'
    assert_select 'h3.discount-statement', text: 'Buy your first Package before your Trial expires with a 20% online discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 7,600'
    assert_select 'li', text: 'Save Rs. 1,900'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 20,400'
    assert_select 'li', text: 'Save Rs. 5,100'
    # items in the razorpay form
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='7600']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='20400']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_trialbeforeexpiry.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client_for_ongoing_trial.id}']", count: 2
  end

  test 'test shop items correct for client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    get client_shop_path(@account_client_for_expired_trial.client)

    assert_template 'client/dynamic_pages/shop'
    assert_select 'h3.discount-statement', text: 'Buy your first Package with a 15% online discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div', text: 'unlimited 1 week trial', count: 0
    assert_select 'div', text: 'Try our classes. Meet our people', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 8,100'
    assert_select 'li', text: 'Save Rs. 1,400'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 21,700'
    assert_select 'li', text: 'Save Rs. 3,800'
    # items in the razorpay form
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='8100']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='21700']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_trialafterexpiry.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client_for_expired_trial.id}']", count: 2
  end

  test 'test shop items correct for new client' do
    log_in_as(@account_new_client)
    get client_shop_path(@account_new_client.client)

    assert_template 'client/dynamic_pages/shop'
    assert_empty response.body.scan(/Buy your first Package/)
    assert_empty response.body.scan(/Renew your Package/)
    assert_select 'div.trial-name', text: 'unlimited 1 week trial'
    assert_select 'p', text: 'Try our classes. Meet our people'
    assert_select 'div', text: 'Our best value memberships for training regularly. The more you train, the better the value!'
    assert_select 'div', { count: 0, text: 'trial' }
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 8,550'
    assert_select 'li', text: 'Save Rs. 950'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 22,950'
    assert_select 'li', text: 'Save Rs. 2,550'
    # items in the razorpay form
    # trial
    assert_select "form input[type=hidden][name=product_id][value='#{@product_trial.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_trial.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='1500']", count: 1
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='8550']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='22950']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_firstpackage.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_new_client.id}']", count: 3
  end
end
