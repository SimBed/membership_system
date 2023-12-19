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

    assert_template 'client/clients/book'
    # puts @response.parsed_body
    # 1 form for razorpay
    assert_select 'form'
    Setting.renew_online = false
    get client_book_path(@account_client.client)

    assert_select 'form', false
    Setting.renew_online = true
    Setting.days_remain = 60
    get client_book_path(@account_client.client)

    assert_select 'form'
    Setting.days_remain = 58
    get client_book_path(@account_client.client)

    assert_select 'form', false
  end

  test 'renewal details correct for client with ongoing package' do
    log_in_as(@account_client)
    follow_redirect!

    assert_template 'client/clients/book'
    assert_select 'p', text: 'Renew your Package before expiry with a 5% online discount!'
    assert_select 'p', text: 'Group - Unlimited Classes 3 Months'
    assert_select 's', text: 'Rs. 25,500'
    assert_select 'span', text: 'Rs. 24,250'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='24250']"
    assert_select "input[type=hidden][name='renewal_discount_id'][value='#{@discount_beforeexpiry.id}']"
    assert_select "input[type=hidden][name='status_discount_id'][value='']"
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client.id}']"
    regexs = /data-amount="2425000"/
    search_result = response.body.scan(regexs)

    refute_empty search_result
  end

  test 'renewal details correct for client with expired package' do
    log_in_as(@account_client)
    # retire package
    purchase = @account_client.client.purchases.last
    # Unneccessarily engineered method of updating purchase
    # travel_to(purchase.expiry_date.advance(days:1))
    # purchase.update(status: purchase.status_calc)
    purchase.update_column(:status, 'expired')
    get client_book_path(@account_client.client)
    # puts @response.parsed_body
    assert_select 'p', text: 'Your Group Package has expired. Renew your Package now!'
    assert_select 'p', text: 'Group - Unlimited Classes 3 Months'
    assert_select 's', false
    assert_select 'span', text: 'Rs. 25,500'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='25500']"
    assert_select "input[type=hidden][name='renewal_discount_id'][value='']"
    assert_select "input[type=hidden][name='status_discount_id'][value='']"
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client.id}']"
    regexs = /data-amount="2550000"/
    search_result = response.body.scan(regexs)

    refute_empty search_result
  end

  test 'renewal details correct for client with ongoing trial' do
    log_in_as(@account_client_for_ongoing_trial)
    follow_redirect!

    assert_template 'client/clients/book'
    # puts @response.parsed_body
    assert_select 'p', text: 'Buy your first Package before your trial expires with a 20% online discount!'
    assert_select 'p', text: 'Group - Unlimited Classes 3 Months'
    assert_select 's', text: 'Rs. 25,500'
    assert_select 'span', text: 'Rs. 20,400'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='20400']"
    assert_select "input[type=hidden][name='renewal_discount_id'][value='#{@discount_trialbeforeexpiry.id}']"
    assert_select "input[type=hidden][name='status_discount_id'][value='']"
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client_for_ongoing_trial.id}']"
    # refute_empty response.body.scan(/or visit the/)
    regexs = /data-amount="2040000"/
    search_result = response.body.scan(regexs)

    refute_empty search_result
  end

  test 'renewal details correct for client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    follow_redirect!

    assert_template 'client/clients/book'
    assert_select 'p', text: 'Your Trial has expired. Buy your first Package with a 15% online discount!'
    assert_select 'p', text: 'Group - Unlimited Classes 3 Months'
    assert_select 's', text: 'Rs. 25,500'
    assert_select 'span', text: 'Rs. 21,700'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='21700']"
    assert_select "input[type=hidden][name='renewal_discount_id'][value='#{@discount_trialafterexpiry.id}']"
    assert_select "input[type=hidden][name='status_discount_id'][value='']"
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client_for_expired_trial.id}']"
    # refute_empty response.body.scan(/or visit the/)
    regexs = /data-amount="2170000"/
    search_result = response.body.scan(regexs)

    refute_empty search_result
  end

  test 'test shop items correct for client with ongoing package' do
    log_in_as(@account_client)
    get client_shop_path(@account_client.client)

    assert_template 'client/clients/shop'
    # puts @response.parsed_body
    assert_select 'h3', text: 'Renew your Package before expiry with a 5% online discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 9,050'
    refute_empty response.body.scan(/data-amount="905000"/)
    assert_select 'li', text: 'Save Rs. 450'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 24,250'
    refute_empty response.body.scan(/data-amount="2425000"/)
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
    assert_select "input[type=hidden][name='renewal_discount_id'][value='#{@discount_beforeexpiry.id}']", count: 2
    assert_select "input[type=hidden][name='status_discount_id'][value='']", count: 2
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client.id}']", count: 2
  end

  test 'test shop items correct for client with expired package' do
    log_in_as(@account_client)
    # retire package
    purchase = @account_client.client.purchases.last
    # travel_to(purchase.expiry_date.advance(days:1))
    # purchase.update(status: purchase.status_calc)
    purchase.update_column(:status, 'expired')
    get client_shop_path(@account_client.client)

    assert_template 'client/clients/shop'
    # puts @response.parsed_body
    assert_empty response.body.scan(/Renew your Package/)
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', count: 0
    assert_select 'div.discount-price', text: 'Rs. 9,500'
    refute_empty response.body.scan(/data-amount="950000"/)
    assert_empty response.body.scan(/Save Rs./)
    assert_select 'div.discount-price', text: 'Rs. 25,500'
    refute_empty response.body.scan(/data-amount="2550000"/)
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
    assert_select "input[type=hidden][name='renewal_discount_id'][value='']", count: 2
    assert_select "input[type=hidden][name='status_discount_id'][value='']", count: 2
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client.id}']", count: 2
  end

  test 'test shop items correct for client with ongoing trial' do
    log_in_as(@account_client_for_ongoing_trial)
    get client_shop_path(@account_client_for_ongoing_trial.client)

    assert_template 'client/clients/shop'
    assert_select 'h3', text: 'Buy your first Package before your trial expires with a 20% online discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 7,600'
    refute_empty response.body.scan(/data-amount="760000"/)
    assert_select 'li', text: 'Save Rs. 1,900'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 20,400'
    refute_empty response.body.scan(/data-amount="2040000"/)
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
    assert_select "input[type=hidden][name='renewal_discount_id'][value='#{@discount_trialbeforeexpiry.id}']", count: 2
    assert_select "input[type=hidden][name='status_discount_id'][value='']", count: 2
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client_for_ongoing_trial.id}']", count: 2
  end

  test 'test shop items correct for client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    get client_shop_path(@account_client_for_expired_trial.client)

    assert_template 'client/clients/shop'
    assert_select 'h3', text: 'Buy your first Package with a 15% online discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div', text: 'unlimited 1 week trial', count: 0
    assert_select 'div', text: 'Try our classes. Meet our people', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 8,100'
    refute_empty response.body.scan(/data-amount="810000"/)
    assert_select 'li', text: 'Save Rs. 1,400'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 21,700'
    refute_empty response.body.scan(/data-amount="2170000"/)
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
    assert_select "input[type=hidden][name='renewal_discount_id'][value='#{@discount_trialafterexpiry.id}']", count: 2
    assert_select "input[type=hidden][name='status_discount_id'][value='']", count: 2
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client_for_expired_trial.id}']", count: 2
  end

  test 'test shop items correct for new client' do
    log_in_as(@account_new_client)
    get client_shop_path(@account_new_client.client)

    assert_template 'client/clients/shop'
    # puts @response.parsed_body
    assert_empty response.body.scan(/Buy your first Package/)
    assert_empty response.body.scan(/Renew your Package/)
    assert_select 'div', text: 'unlimited 1 week trial'
    assert_select 'div', text: 'Try our classes. Meet our people'
    assert_select 'div', text: 'Our best value memberships for training regularly. The more you train, the better the value!'
    # assert_select "div", false, text: "Our flexible membership is best value if you plan to train with us twice per week or less."
    # assert_select "div.base-price", text: "Rs. 1,500", count: 0 # base-price class has a strikethrough, dont want that
    # assert_select "div.discount-price", text: "Rs. 1,500"
    assert_select 'div', { count: 0, text: 'trial' }
    refute_empty response.body.scan(/data-amount="150000"/)
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 8,550'
    refute_empty response.body.scan(/data-amount="855000"/)
    assert_select 'li', text: 'Save Rs. 950'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 22,950'
    refute_empty response.body.scan(/data-amount="2295000"/)
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
    assert_select "input[type=hidden][name='renewal_discount_id'][value='#{@discount_firstpackage.id}']", count: 2
    assert_select "input[type=hidden][name='status_discount_id'][value='']", count: 2
    assert_select "input[type=hidden][name='oneoff_discount_id'][value='']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_new_client.id}']", count: 3
  end
end
