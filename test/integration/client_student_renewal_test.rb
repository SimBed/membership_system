require "test_helper"

class ClientStudentRenewalTest < ActionDispatch::IntegrationTest
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
    # @discount_trialbeforeexpiry = discounts(:trialbeforeexpiry)
    # @discount_trialafterexpiry = discounts(:trialafterexpiry)
    # @discount_beforeexpiry = discounts(:beforeexpiry)
    # @discount_firstpackage = discounts(:firstpackage)
    @discount_student = discounts(:student)
    # studentise
    @account_client.client.update(student: true)
    @account_client_for_ongoing_trial.client.update(student: true)
    @account_client_for_expired_trial.client.update(student: true)
    @account_new_client.client.update(student: true)
  end

  test 'renewal details correct for student client with ongoing package' do
    log_in_as(@account_client)
    follow_redirect!
    # File.write('test_output.html', response.body)
    assert_template 'client/bookings/index'
    assert_select 'div', text: '25% online student discount!'
    assert_select 'div', text: 'Group - Unlimited Classes 3 Months'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='19150']"
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client.id}']"
  end

  test 'renewal details correct for student client with expired package' do
    log_in_as(@account_client)
    purchase = @account_client.client.purchases.last
    purchase.update_column(:status, 'expired')
    get client_bookings_path(@account_client.client)
    assert_select 'div', text: '25% online student discount!'
    assert_select 'div', text: 'Group - Unlimited Classes 3 Months'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='19150']"
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client.id}']"
  end

  test 'renewal details correct for student client with ongoing trial' do
    log_in_as(@account_client_for_ongoing_trial)
    follow_redirect!

    assert_template 'client/bookings/index'
    # puts @response.parsed_body
    assert_select 'div', text: '25% online student discount!'
    assert_select 'div', text: 'Group - Unlimited Classes 3 Months'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='19150']"
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client_for_ongoing_trial.id}']"
  end

  test 'renewal details correct for student client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    follow_redirect!

    assert_template 'client/bookings/index'
    assert_select 'div', text: '25% online student discount!'
    assert_select 'div', text: 'Group - Unlimited Classes 3 Months'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select "input[type=hidden][name='product_id'][value='#{@product_unlimited3m.id}']"
    assert_select "input[type=hidden][name='price_id'][value='#{@price_uc3m_base.id}']"
    assert_select "input[type=hidden][name='price'][value='19150']"
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']"
    assert_select "input[type=hidden][name='account_id'][value='#{@account_client_for_expired_trial.id}']"
  end

  test 'test shop items correct for student client with ongoing package' do
    log_in_as(@account_client)
    get client_shop_path(@account_client.client)

    assert_template 'client/dynamic_pages/shop'
    assert_select 'h3.discount-statement', text: 'Buy your Package with a 25% online student discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 7,150'
    # refute_empty response.body.scan(/data-amount="905000"/)
    assert_select 'li', text: 'Save Rs. 2,350'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select 'li', text: 'Save Rs. 6,350'
    # items in the razorpay form
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='7150']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='19150']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client.id}']", count: 2
  end

  test 'test shop items correct for student client with expired package' do
    log_in_as(@account_client)
    # retire package
    purchase = @account_client.client.purchases.last
    purchase.update_column(:status, 'expired')
    get client_shop_path(@account_client.client)
    assert_template 'client/dynamic_pages/shop'
    assert_select 'h3.discount-statement', text: 'Buy your Package with a 25% online student discount!'
    assert_empty response.body.scan(/Renew your Package/)
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 7,150'
    assert_select 'li', text: 'Save Rs. 2,350'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select 'li', text: 'Save Rs. 6,350'
    # items in the razorpay form
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='7150']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='19150']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client.id}']", count: 2
  end

  test 'test shop items correct for student client with ongoing trial' do
    log_in_as(@account_client_for_ongoing_trial)
    get client_shop_path(@account_client_for_ongoing_trial.client)
    assert_template 'client/dynamic_pages/shop'
    assert_select 'h3.discount-statement', text: 'Buy your Package with a 25% online student discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 7,150'
    assert_select 'li', text: 'Save Rs. 2,350'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select 'li', text: 'Save Rs. 6,350'
    # items in the razorpay form
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='7150']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='19150']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client_for_ongoing_trial.id}']", count: 2
  end

  test 'test shop items correct for client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    get client_shop_path(@account_client_for_expired_trial.client)

    assert_template 'client/dynamic_pages/shop'
    assert_select 'h3.discount-statement', text: 'Buy your Package with a 25% online student discount!'
    assert_select 'div.base-price', text: 'Rs. 1,500', count: 0
    assert_select 'div.discount-price', text: 'Rs. 1,500', count: 0
    assert_select 'div', text: 'TRIAL', count: 0
    assert_select 'div', text: 'unlimited 1 week trial', count: 0
    assert_select 'div', text: 'Try our classes. Meet our people', count: 0
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 7,150'
    assert_select 'li', text: 'Save Rs. 2,350'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select 'li', text: 'Save Rs. 6,350'
    # items in the razorpay form
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='7150']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='19150']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_client_for_expired_trial.id}']", count: 2
  end

  # this situation shouldnt normally arise
  test 'test shop items correct for new student client' do
    log_in_as(@account_new_client)
    get client_shop_path(@account_new_client.client)

    assert_template 'client/dynamic_pages/shop'
    # File.write('test_output.html', response.body)
    assert_empty response.body.scan(/Buy your Package with a 25% online student discount!/)
    assert_empty response.body.scan(/Buy your first Package/)
    assert_empty response.body.scan(/Renew your Package/)
    assert_select 'div.trial-name', text: 'unlimited 1 week trial'
    assert_select 'p', text: 'Try our classes. Meet our people'
    assert_select 'div', text: 'Our best value memberships for training regularly. The more you train, the better the value!'
    assert_select 'div', { count: 0, text: 'trial' }
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 7,150'
    assert_select 'li', text: 'Save Rs. 2,350'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 19,150'
    assert_select 'li', text: 'Save Rs. 6,350'
    assert_select 'li', text: 'We offer a 25% online discount for monthly Packages to full-time students'
    # items in the razorpay form
    # trial
    assert_select "form input[type=hidden][name=product_id][value='#{@product_trial.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_trial.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='1500']", count: 1
    # 1 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited1m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc1m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='7150']", count: 1
    # 3 month product
    assert_select "form input[type=hidden][name=product_id][value='#{@product_unlimited3m.id}']", count: 1
    assert_select "form input[type=hidden][name=price_id][value='#{@price_uc3m_base.id}']", count: 1
    assert_select "input[type=hidden][name='price'][value='19150']", count: 1
    # across all shop products listed
    assert_select "input[type=hidden][name='discount_id'][value='#{@discount_student.id}']", count: 2
    assert_select "form input[type=hidden][name=account_id][value='#{@account_new_client.id}']", count: 3
  end
end
