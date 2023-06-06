# frozen_string_literal: true

require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = Account.new(email: 'user@example.com',
                           password: 'foobar',
                           password_confirmation: 'foobar',
                           ac_type: 'client')
    @client_no_account = clients(:bhavik)
  end

  test 'should be valid' do
    assert_predicate @account, :valid?
  end

  test 'email should be present' do
    @account.email = '     '

    refute_predicate @account, :valid?
  end

  test 'ac_type should be present' do
    @account.ac_type = '     '

    refute_predicate @account, :valid?
  end

  test 'email addresses should be unique' do
    duplicate_account = @account.dup
    duplicate_account.email = @account.email.upcase
    @account.save

    refute_predicate duplicate_account, :valid?
  end

  test 'password should be present (nonblank)' do
    @account.password = @account.password_confirmation = ' ' * 6

    refute_predicate @account, :valid?
  end

  test 'password should have a minimum length' do
    @account.password = @account.password_confirmation = 'a' * 5

    refute_predicate @account, :valid?
  end

  test 'authenticated? should return false for an account with nil remember_digest' do
    refute @account.authenticated?(:remember, '')
  end

  test 'Account#setup_for client' do
    assert_nil @client_no_account.account_id
    assert_difference 'Account.count' do
      Account.setup_for(@client_no_account)
    end

    refute_nil @client_no_account.account_id
  end
end
