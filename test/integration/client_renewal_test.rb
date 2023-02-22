require "test_helper"

class ClientRenewalTest < ActionDispatch::IntegrationTest
  setup do
    @account_client = accounts(:client_for_unlimited)
    @account_client_for_expired_trial = accounts(:client_for_expired_trial)
    @client_for_unlimited = @account_client.clients.first
    @client_for_expired_trial = @account_client_for_expired_trial.clients.first
    @tomorrows_class_early = wkclasses(:wkclass_for_booking_early)
    travel_to(@tomorrows_class_early.start_time.beginning_of_day) # 22/4
  end

  test 'renewal form appears correctly' do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    # puts @response.parsed_body    
    assert_select "form", count: 1   
    # get client_shop_path(@client)
    # assert_template 'public_pages/shop'
    Setting.renew_online = false
    get client_book_path(@client_for_unlimited)
    assert_select "form", false
    Setting.renew_online = true
    # client's purchase has 59 days to go
    Setting.days_remain = 60
    get client_book_path(@client_for_unlimited)
    assert_select "form", count: 1
    Setting.days_remain = 58
    get client_book_path(@client_for_unlimited)
    assert_select "form", false    
  end

  test 'renewal rate applied correctly for client with ongoing package' do
    log_in_as(@account_client)
    follow_redirect!
    assert_template 'client/clients/book'
    # puts @response.parsed_body    
    regexs = /data-amount="2295000"/
    search_result = response.body.scan(regexs)
    # byebug
    refute_empty search_result
  end

  test 'renewal rate applied correctly for client with expired trial' do
    log_in_as(@account_client_for_expired_trial)
    follow_redirect!
    assert_template 'client/clients/book'
    # puts @response.parsed_body
    regexs = /data-amount="2025000"/
    search_result = response.body.scan(regexs)
    # byebug
    refute_empty search_result
  end

end
