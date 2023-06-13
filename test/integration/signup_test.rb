require 'test_helper'

class SignupTest < ActionDispatch::IntegrationTest
  test 'blank signup form' do
    get signup_path

    assert_template 'public_pages/signup'
    post '/signup', params:
      { client:
       { first_name: '',
         last_name: '',
         email: '',
         whatsapp_country_code: 'IN',
         whatsapp_raw: '',
         phone_raw: '',
         instagram: '',
         terms_of_service: '0' } }

    assert_template 'public_pages/signup'
    assert_select 'h2', text: '5 errors prohibited this account from being created:'
    assert_select 'li', text: "First name can't be blank"
    assert_select 'li', text: "Last name can't be blank"
    assert_select 'li', text: "Email can't be blank"
    assert_select 'li', text: "Whatsapp can't be blank"
    assert_select 'li', text: 'Terms of service must be accepted'
  end

  test 'invalid whatsapp' do
    get signup_path

    assert_template 'public_pages/signup'
    post '/signup', params:
      { client:
       { first_name: 'Dani',
         last_name: 'Boi',
         email: 'daniboi@gmail.com',
         whatsapp_country_code: 'IN',
         whatsapp_raw: '123456789',
         phone_raw: '',
         instagram: '',
         terms_of_service: '1' } }

    assert_template 'public_pages/signup'
    assert_select 'h2', text: '1 error prohibited this account from being created:'
    assert_select 'li', text: 'Whatsapp is invalid'
    assert_select 'form input[type=text][value="Dani"]'
    assert_select 'form input[type=text][value="Boi"]'
    assert_select 'form input[type=text][value="daniboi@gmail.com"]'
    assert_select 'form input[type=text][value^="daniboi"]'
    assert_select 'option[selected=selected]', 'IN +91'
    assert_select 'form input[type=text][value="123456789"]'
  end

  test 'invalid GB whatsapp' do
    get signup_path

    assert_template 'public_pages/signup'
    post '/signup', params:
      { client:
       { first_name: 'Dani',
         last_name: 'Boi',
         email: 'daniboi@gmail.com',
         whatsapp_country_code: 'GB',
         whatsapp_raw: '123456789',
         phone_raw: '',
         instagram: '',
         terms_of_service: '1' } }

    assert_template 'public_pages/signup'
    assert_select 'h2', text: '1 error prohibited this account from being created:'
    assert_select 'li', text: 'Whatsapp is invalid'
    assert_select 'form input[type=text][value="Dani"]'
    assert_select 'form input[type=text][value="Boi"]'
    assert_select 'form input[type=text][value="daniboi@gmail.com"]'
    assert_select 'form input[type=text][value^="daniboi"]'
    assert_select 'option[selected=selected]', 'GB +44'
    assert_select 'form input[type=text][value="123456789"]'
  end

  test 'invalid duplicate name' do
    assert_difference -> { Account.count } => 1, -> { Client.count } => 1, -> { Assignment.count } => 1 do
      post '/signup', params:
        { client:
         { first_name: 'Dani',
           last_name: 'Boi',
           email: 'daniboi@gmail.com',
           whatsapp_country_code: 'GB',
           whatsapp_raw: '1234567891',
           phone_raw: '',
           instagram: '',
           terms_of_service: '1' } }
    end
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: 'Dani',
           last_name: 'Boi',
           email: 'daniboiboi@gmail.com',
           whatsapp_country_code: 'GB',
           whatsapp_raw: '1114567891',
           phone_raw: '',
           instagram: '',
           terms_of_service: '1' } }
    end
  end

  test 'valid signup (Indian whatsapp)' do
    get signup_path

    assert_template 'public_pages/signup'
    # https://apidock.com/rails/v5.2.3/ActiveSupport/Testing/Assertions/assert_difference
    assert_difference -> { Account.count } => 1, -> { Client.count } => 1 do
      post '/signup', params:
      { client:
      { first_name: 'Dani',
        last_name: 'Boi',
        email: 'daniboi@gmail.com',
        whatsapp_country_code: 'IN',
        whatsapp_raw: '1234567891',
        phone_raw: '9123456789',
        instagram: '#myinsta',
        terms_of_service: '1' } }
    end
    client = Client.last

    assert_equal '+911234567891', client.whatsapp
    assert_equal '+919123456789', client.phone
    assert_redirected_to client_shop_path(assigns(:client).id)
    follow_redirect!
    # same tests as for 'test shop items correct for new client' from client_renewal_test
    assert_template 'client/clients/shop'
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
  end

  test 'valid signup (GB whatsapp)' do
    get signup_path

    assert_template 'public_pages/signup'
    # https://apidock.com/rails/v5.2.3/ActiveSupport/Testing/Assertions/assert_difference
    assert_difference -> { Account.count } => 1, -> { Client.count } => 1 do
      post '/signup', params:
      { client:
      { first_name: 'Dani',
        last_name: 'Boi',
        email: 'daniboi@gmail.com',
        whatsapp_country_code: 'GB',
        whatsapp_raw: '1234567891',
        phone_raw: '9123456789',
        instagram: '#myinsta',
        terms_of_service: '1' } }
    end
    client = Client.last

    assert_equal '+441234567891', client.whatsapp
    assert_equal '+919123456789', client.phone
    assert_redirected_to client_shop_path(assigns(:client).id)
    follow_redirect!

    assert_template 'client/clients/shop'
  end
end
