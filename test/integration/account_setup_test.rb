require 'test_helper'

class AccountSetupTest < ActionDispatch::IntegrationTest
  include SessionsHelper
  def setup
    @superadmin = accounts(:superadmin)
    @admin = accounts(:admin)
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
      post purchases_path, params: { purchase: { client_id: @client.id,
                                                       product_id: @product.id, price_id: @price.id,
                                                       charge: 22_950, dop: '2022-02-15', payment_mode: 'Cash',
                                                       payment_attributes: {amount: 22_950, payment_mode: 'Cash'} } }
    end
    new_account = Account.last
    # the new account has been given a random password, so lets reset it so we can login easily
    new_account.update(password: 'password', password_confirmation: 'password')
    log_in_as(new_account)

    assert_equal current_account, Account.last
    assert_equal('client', current_role)
    # account shouldnt be created on 2nd purchase
    assert_difference -> { Account.count } => 0, -> { Assignment.count } => 0 do
      post purchases_path, params: { purchase: { client_id: @client.id,
                                                       product_id: @product.id, price_id: @price.id,
                                                       charge: 22_950, dop: '2022-05-15', payment_mode: 'Cash' },
                                                       payment_attributes: {amount: 22_950, payment_mode: 'Cash'} }
    end
  end

  test 'account created with client role for existing client at admin request' do
    log_in_as(@admin)
    @client.save
    assert_difference -> { Account.count } => 1, -> { Assignment.count } => 1 do
      post accounts_path, params: { email: @client.email,
                                          id: @client.id,
                                          ac_type: 'client' }
    end
    new_account = Account.last
    # the new account has been given a random password, so lets reset it so we can login easily
    new_account.update(password: 'password', password_confirmation: 'password')
    log_in_as(new_account)

    assert_equal current_account, Account.last
    assert_equal('client', current_role)
  end
end
