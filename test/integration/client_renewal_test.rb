require "test_helper"

class ClientRenewalTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @account_client_for_ongoing_trial = accounts(:client_for_ongoing_trial)
    @account_client_for_expired_trial = accounts(:client_for_expired_trial)
    @client_for_unlimited = @account_client.clients.first
    @client_for_ongoing_trial = @account_client_for_ongoing_trial.clients.first
    @client_for_expired_trial = @account_client_for_expired_trial.clients.first
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
    assert_select "p", text: "Renew your Package before expiry with a 10% online discount!" 
    assert_select "p", text: "Group - Unlimited Classes 3 Months"  
    assert_select "s", text: "Rs. 25,500"
    assert_select "span", text: "Rs. 22,950"  
    regexs = /data-amount="2295000"/
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
    # puts @response.parsed_body
    assert_select "p", text: "Your Trial has expired. Buy your first Package with a #{Setting.post_expiry_trial_renewal}% online discount!" 
    assert_select "p", text: "Group - Unlimited Classes 3 Months"  
    assert_select "s", text: "Rs. 25,500"
    assert_select "span", text: "Rs. 22,950"
    refute_empty response.body.scan(/or visit the/)
    regexs = /data-amount="2295000"/
    search_result = response.body.scan(regexs)
    refute_empty search_result
  end

end
