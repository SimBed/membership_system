require "test_helper"

class ClientRenewalTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @account_client_for_ongoing_trial = accounts(:client_for_ongoing_trial)
    @account_client_for_expired_trial = accounts(:client_for_expired_trial)
    @account_new_client = accounts(:client_no_purchases)
    @client_for_unlimited = @account_client.clients.first
    @client_for_ongoing_trial = @account_client_for_ongoing_trial.clients.first
    @client_for_expired_trial = @account_client_for_expired_trial.clients.first
    @client_no_purchases = @account_new_client.clients.first
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
  end

  test 'renewal form appears correctly on booking page for client with ongoing package (with 59 days to go) and responds to settings' do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select "form", count: 1   
    # get client_shop_path(@client)
    # assert_template 'public_pages/shop'
    Setting.renew_online = false
    get client_book_path(@client_for_unlimited)
    assert_select "form", false
    Setting.renew_online = true
    Setting.days_remain = 60
    get client_book_path(@client_for_unlimited)
    assert_select "form", count: 1
    Setting.days_remain = 58
    get client_book_path(@client_for_unlimited)
    assert_select "form", false    
  end

  test 'renewal details correct for client with ongoing package' do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select "p", text: "Renew your Package before expiry with a #{Setting.pre_expiry_package_renewal}% online discount!" 
    assert_select "p", text: "Group - Unlimited Classes 3 Months"  
    assert_select "s", text: "Rs. 25,500"
    assert_select "span", text: "Rs. 22,950"  
    regexs = /data-amount="2295000"/
    search_result = response.body.scan(regexs)
    refute_empty search_result
  end

  test 'renewal details correct for client with expired package' do
    log_in_as(@account_client)
    # retire package
    purchase = @client_for_unlimited.purchases.last    
    travel_to(purchase.expiry_date.advance(days:1))
    purchase.update(status: purchase.status_calc)
    get client_book_path(@client_for_unlimited)
    # puts @response.parsed_body    
    assert_select "p", text: "Your Package has expired. Renew your Package now!" 
    assert_select "p", text: "Group - Unlimited Classes 3 Months"  
    assert_select "s", false
    assert_select "span", text: "Rs. 25,500"  
    regexs = /data-amount="2550000"/
    search_result = response.body.scan(regexs)
    refute_empty search_result
  end

  test 'renewal details correct for client with ongoing trial' do
    log_in_as(@account_client_for_ongoing_trial)
    follow_redirect!
    assert_template 'client/clients/book'
    # puts @response.parsed_body
    assert_select "p", text: "Buy your first Package before your trial expires with a #{Setting.pre_expiry_trial_renewal}% online discount!" 
    assert_select "p", text: "Group - Unlimited Classes 3 Months"  
    assert_select "s", text: "Rs. 25,500"
    assert_select "span", text: "Rs. 20,400"
    refute_empty response.body.scan(/or visit the/)
    regexs = /data-amount="2040000"/
    search_result = response.body.scan(regexs)
    refute_empty search_result
  end

  test 'renewal details correct for client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    follow_redirect!
    assert_template 'client/clients/book'
    assert_select "p", text: "Your Trial has expired. Buy your first Package with a #{Setting.post_expiry_trial_renewal}% online discount!" 
    assert_select "p", text: "Group - Unlimited Classes 3 Months"  
    assert_select "s", text: "Rs. 25,500"
    assert_select "span", text: "Rs. 21,700"
    refute_empty response.body.scan(/or visit the/)
    regexs = /data-amount="2170000"/
    search_result = response.body.scan(regexs)
    refute_empty search_result
  end

  test 'test shop items correct for client with ongoing package' do
    log_in_as(@account_client)
    get client_shop_path(@client_for_unlimited)
    assert_template 'public_pages/shop'
    # puts @response.parsed_body    
    assert_select "h3", text: "Renew your Package before expiry with a #{Setting.pre_expiry_package_renewal}% online discount!"
    assert_select "div.base-price", text: "Rs. 1,500", count: 0
    assert_select "div.discount-price", text: "Rs. 1,500", count: 0
    assert_select "div", text: "TRIAL", count: 0        
    assert_select "div.base-price", text: "Rs. 9,500"  
    assert_select "div.discount-price", text: "Rs. 8,550"
    refute_empty response.body.scan(/data-amount="855000"/)
    assert_select "div.base-price", text: "Rs. 25,500"  
    assert_select "div.discount-price", text: "Rs. 22,950"
    refute_empty response.body.scan(/data-amount="2295000"/)
  end  

  test 'test shop items correct for client with ongoing trial' do
    log_in_as(@account_client_for_ongoing_trial)
    get client_shop_path(@client_for_ongoing_trial)
    assert_template 'public_pages/shop'
    assert_select "h3", text: "Buy your first Package before your trial expires with a #{Setting.pre_expiry_trial_renewal}% online discount!"
    assert_select "div.base-price", text: "Rs. 1,500", count: 0
    assert_select "div.discount-price", text: "Rs. 1,500", count: 0
    assert_select "div", text: "TRIAL", count: 0            
    assert_select "div.base-price", text: "Rs. 9,500"  
    assert_select "div.discount-price", text: "Rs. 7,600"
    refute_empty response.body.scan(/data-amount="760000"/)
    assert_select "div.base-price", text: "Rs. 25,500"  
    assert_select "div.discount-price", text: "Rs. 20,400"
    refute_empty response.body.scan(/data-amount="2040000"/)
  end  

  test 'test shop items correct for client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    get client_shop_path(@client_for_expired_trial)
    assert_template 'public_pages/shop'
    assert_select "h3", text: "Buy your first Package with a #{Setting.post_expiry_trial_renewal}% online discount!"
    assert_select "div.base-price", text: "Rs. 1,500", count: 0
    assert_select "div.discount-price", text: "Rs. 1,500", count: 0
    assert_select "div", text: "TRIAL", count: 0        
    assert_select "div.base-price", text: "Rs. 9,500"  
    assert_select "div.discount-price", text: "Rs. 8,080"
    refute_empty response.body.scan(/data-amount="808000"/)
    assert_select "div.base-price", text: "Rs. 25,500"  
    assert_select "div.discount-price", text: "Rs. 21,700"
    refute_empty response.body.scan(/data-amount="2170000"/)
  end  

  test 'test shop items correct for new client' do
    log_in_as(@account_new_client)
    get client_shop_path(@client_no_purchases)
    assert_template 'public_pages/shop'
    # puts @response.parsed_body    
    assert_select "h3", text: "Buy your first Package with a #{Setting.post_expiry_trial_renewal}% online discount!" 
    assert_select "div.base-price", text: "Rs. 1,500", count: 0 # base-price class has a strikethrough, dont want that
    assert_select "div.discount-price", text: "Rs. 1,500"
    assert_select "div", text: "trial"
    refute_empty response.body.scan(/data-amount="150000"/)
    assert_select "div.base-price", text: "Rs. 9,500"  
    assert_select "div.discount-price", text: "Rs. 8,550"
    refute_empty response.body.scan(/data-amount="855000"/)
    assert_select "div.base-price", text: "Rs. 25,500"  
    assert_select "div.discount-price", text: "Rs. 22,950"
    refute_empty response.body.scan(/data-amount="2295000"/)
  end  

end