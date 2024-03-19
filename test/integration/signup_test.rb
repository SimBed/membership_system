require 'test_helper'

class SignupTest < ActionDispatch::IntegrationTest
  include SessionsHelper

  def setup
    @existing_client_account = accounts(:client_for_unlimited)
    @exiting_client_with_account = @existing_client_account.client
    @existing_client_without_account = clients(:bhavik)
    # changing all the Account fixtures just created to have been created a day earlier, so daily account limit not triggered
    # https://docs.rubocop.org/rubocop/configuration.html#:~:text=Disabling%20Cops%20within%20Source%20Code,-One%20or%20more&text=In%20cases%20where%20you%20want,an%20alias%20of%20rubocop%3Adisable%20.&text=One%20or%20more%20cops%20can,end%2Dof%2Dline%20comment.
    # rubocop:disable Rails/SkipsModelValidations
    Account.all.update_all(created_at: Time.zone.now.advance(days: -1))
    # rubocop:enable Rails/SkipsModelValidations
  end

  test 'blank signup form' do
    get signup_path

    assert_template 'public_pages/home/signup'
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

    assert_template 'public_pages/home/signup'
    assert_select 'h2', text: '5 errors prohibited this account from being created:'
    assert_select 'li', text: "First name can't be blank"
    assert_select 'li', text: "Last name can't be blank"
    assert_select 'li', text: "Email can't be blank"
    assert_select 'li', text: "Whatsapp can't be blank"
    assert_select 'li', text: 'Terms of service must be accepted'
  end

  test 'invalid whatsapp' do
    get signup_path

    assert_template 'public_pages/home/signup'
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

    assert_template 'public_pages/home/signup'
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

    assert_template 'public_pages/home/signup'
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

    assert_template 'public_pages/home/signup'
    assert_select 'h2', text: '1 error prohibited this account from being created:'
    assert_select 'li', text: 'Whatsapp is invalid'
    assert_select 'form input[type=text][value="Dani"]'
    assert_select 'form input[type=text][value="Boi"]'
    assert_select 'form input[type=text][value="daniboi@gmail.com"]'
    assert_select 'form input[type=text][value^="daniboi"]'
    assert_select 'option[selected=selected]', 'GB +44'
    assert_select 'form input[type=text][value="123456789"]'
  end

  # reconsider client model validations, as we dont want to lose new signups because of name duplication
  test 'invalid duplicate name' do
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: @existing_client_without_account.first_name,
           last_name: @existing_client_without_account.last_name,
           email: 'unique@gmail.com',
           whatsapp_country_code: 'GB',
           whatsapp_raw: '1234567891',
           phone_raw: '',
           instagram: '',
           terms_of_service: '1' } }
    end
  end

  test 'invalid duplicate email' do
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'Shah',
           email: @existing_client_without_account.last_name,
           whatsapp_country_code: 'GB',
           whatsapp_raw: '1234567891',
           phone_raw: '',
           instagram: '',
           terms_of_service: '1' } }
    end
  end

  test 'invalid duplicate whatsapp' do
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'Shah',
           email: 'unique@gmail.com',
           whatsapp_country_code: 'IN',
           whatsapp_raw: @existing_client_without_account.whatsapp.slice(3, 10),
           phone_raw: '',
           instagram: '',
           terms_of_service: '1' } }
    end
  end

  # NOTE: whatsapp cant be blank on signup (but phone can)
  test 'invalid duplicate phone' do
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params:
        { client:
         { first_name: 'uniquefirstname',
           last_name: 'Shah',
           email: 'unique@gmail.com',
           whatsapp_country_code: 'IN',
           whatsapp_raw: "#{@existing_client_without_account.phone.slice(4, 10)}5",
           phone_raw: @existing_client_without_account.phone.slice(3, 10),
           instagram: '',
           terms_of_service: '1' } }
    end
  end

  test 'valid signup (Indian whatsapp)' do
    get signup_path

    assert_template 'public_pages/home/signup'
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
    assert_select 'div', { count: 0, text: 'trial' }
    refute_empty response.body.scan(/data-amount="150000"/)
    assert_select 'div.base-price', text: 'Rs. 9,500'
    assert_select 'div.discount-price', text: 'Rs. 8,550'
    refute_empty response.body.scan(/data-amount="855000"/)
    assert_select 'li', text: 'Save Rs. 950'
    assert_select 'div.base-price', text: 'Rs. 25,500'
    assert_select 'div.discount-price', text: 'Rs. 22,950'
    refute_empty response.body.scan('data-amount="2295000"')
    assert_select 'li', text: 'Save Rs. 2,550'

    log_out
    new_account = Account.last
    # the new account has been given a random password, so lets rest it so we can login easily
    new_account.update(password: 'password', password_confirmation: 'password')
    log_in_as(new_account)

    assert_equal current_account, Account.last
    assert_equal('client', current_role)
  end

  test 'valid signup (GB whatsapp)' do
    get signup_path

    assert_template 'public_pages/home/signup'
    # https://apidock.com/rails/v5.2.3/ActiveSupport/Testing/Assertions/assert_difference
    assert_difference -> { Account.count } => 1, -> { Client.count } => 1, -> { Assignment.count } => 1 do
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
    log_out
    new_account = Account.last
    # the new account has been given a random password, so lets rest it so we can login easily
    new_account.update(password: 'password', password_confirmation: 'password')
    log_in_as(new_account)

    assert_equal current_account, Account.last
    assert_equal('client', current_role)
  end

  test 'public should not be able to create more than daily limit accounts on any one day' do
    Setting.daily_account_limit.times do |n|
      name = Faker::Name.name
      joe_public = { first_name: name.split[0],
                     last_name: name.split[1],
                     email: "#{name.split.join}@gmail.com",
                     whatsapp_country_code: 'IN',
                     whatsapp_raw: "123456789#{n}",
                     terms_of_service: '1' }
      assert_difference -> { Account.count } => 1, -> { Client.count } => 1, -> { Assignment.count } => 1 do
        post '/signup', params: { client: joe_public }
      end
    end

    name = Faker::Name.name
    joe_public = { first_name: name.split[0],
                   last_name: name.split[1],
                   email: "#{name.split.join}@gmail.com",
                   whatsapp_country_code: 'IN',
                   whatsapp_raw: '1234567880',
                   terms_of_service: '1' }
    assert_difference -> { Account.count } => 0, -> { Client.count } => 0, -> { Assignment.count } => 0 do
      post '/signup', params: { client: joe_public }
    end
  end
end
