require 'test_helper'

class AccountSetupTest < ActionDispatch::IntegrationTest
  include SessionsHelper
  def setup
    @superadmin = accounts(:superadmin)
    @client = Client.new(first_name: 'Amala',
                         last_name: 'Paw',
                         email: 'amala@thespace.in')
    @product = products(:unlimited3m)
    @price = prices(:Uc3mbase)
  end

  test 'account created with client role when client makes first groupex package purchase' do
    log_in_as(@superadmin)
    @client.save
    assert_difference -> { Account.count } => 1, -> { Assignment.count } => 1 do
      post admin_purchases_path, params: { purchase: { client_id: @client.id,
                                                       product_id: @product.id, price_id: @price.id,
                                                       payment: 22_950, dop: '2022-02-15', payment_mode: 'Cash' } }
    end
    new_account = Account.last
    # the new account has been given a random password, so lets reset it so we can login easily
    new_account.update(password: 'password', password_confirmation: 'password')
    log_in_as(new_account)

    assert_equal current_account, Account.last
    assert_equal('client', current_role)
    # account shouldnt be created on 2nd purchase
    assert_difference -> { Account.count } => 0, -> { Assignment.count } => 0 do
      post admin_purchases_path, params: { purchase: { client_id: @client.id,
                                                       product_id: @product.id, price_id: @price.id,
                                                       payment: 22_950, dop: '2022-05-15', payment_mode: 'Cash' } }
    end
  end

  test 'account created with client role when client signs up' do
    get signup_path

    assert_template 'public_pages/signup'
    # https://apidock.com/rails/v5.2.3/ActiveSupport/Testing/Assertions/assert_difference
    assert_difference -> { Account.count } => 1, -> { Client.count } => 1, -> { Assignment.count } => 1 do
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
    log_out
    new_account = Account.last
    # the new account has been given a random password, so lets rest it so we can login easily
    new_account.update(password: 'password', password_confirmation: 'password')
    log_in_as(new_account)

    assert_equal current_account, Account.last
    assert_equal('client', current_role)
  end
end
