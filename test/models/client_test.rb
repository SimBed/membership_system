require 'test_helper'

class ClientTest < ActiveSupport::TestCase
  def setup
    @client = Client.new(first_name: ' amala ',
                         last_name: ' paw ',
                         email: 'amala@thespace.in',
                         phone_raw: '9145678900',
                         whatsapp_raw: '9145678901',
                         whatsapp_country_code: 'IN',
                         instagram: '#paw',
                         note: 'our top client')
    @client2 = clients(:bhavik)
    @client_trial1 = clients(:client_trial_expired)
    @client_trial2 = clients(:client_trial_ongoing)
    @booked_class = wkclasses(:wkclass2)
  end

  test 'should be valid' do
    assert_predicate @client, :valid?
  end

  test 'phone number should be plausible' do
    @client.phone_raw = '914567890'

    refute_predicate @client, :valid?
  end

  test 'whatsapp number should be plausible' do
    @client.whatsapp_raw = '914567890'

    refute_predicate @client, :valid?
  end

  test 'phone number is not mandatory' do
    @client.phone_raw = ''

    assert_predicate @client, :valid?
  end

  test 'whatsapp number mandatory presence on signup only' do
    @client.whatsapp_raw = ''

    assert_predicate @client, :valid?
    # admin is allowed to add a client with blank whatsapp
    @client.modifier_is_client = true

    refute_predicate @client, :valid?
  end

  test 'whatsapp number should be unique' do
    @client.whatsapp_raw = @client2.whatsapp.slice(3, 10)

    refute_predicate @client, :valid?
  end

  test 'phone number should be unique' do
    @client.phone_raw = @client2.phone.slice(3, 10)

    refute_predicate @client, :valid?
  end

  test 'first name should be present' do
    @client.first_name = '     '

    refute_predicate @client, :valid?
  end

  test 'last name should be present' do
    @client.last_name = '     '

    refute_predicate @client, :valid?
  end

  test 'first_name should not be too long' do
    @client.first_name = 'a' * 41

    refute_predicate @client, :valid?
  end

  test 'last_name should not be too long' do
    @client.last_name = 'a' * 41

    refute_predicate @client, :valid?
  end

  test 'full name should be unique' do
    duplicate_named_client = Client.new(first_name: @client.first_name, last_name: @client.last_name)
    @client.save

    refute_predicate duplicate_named_client, :valid?
  end

  test 'uppercase_names method also strips whitespace' do
    roughly_named_client = @client.dup
    roughly_named_client.update(first_name: '  amalu ', last_name: '   meowaw   ')

    assert_equal('Amalu', roughly_named_client.first_name)
    assert_equal('Meowaw', roughly_named_client.last_name)
  end

  test 'email should not be too long' do
    @client.email = "#{'a' * 244}@example.com"

    refute_predicate @client, :valid?
  end

  test 'email validation should accept valid addresses' do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @client.email = valid_address

      assert_predicate @client, :valid?, "#{valid_address.inspect} should be valid"
    end
  end

  test 'email validation should reject invalid addresses' do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com]
    invalid_addresses.each do |invalid_address|
      @client.email = invalid_address

      refute_predicate @client, :valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test 'email addresses should be unique' do
    duplicate_client = @client.dup
    duplicate_client.email = @client.email.upcase
    @client.save

    refute_predicate duplicate_client, :valid?
  end

  test 'email addresses should be saved as lower-case' do
    mixed_case_email = 'Foo@ExAMPle.CoM'
    @client.email = mixed_case_email
    @client.save

    assert_equal mixed_case_email.downcase, @client.reload.email
  end

  test 'name method' do
    @client.save

    assert_equal 'Amala Paw', @client.name
  end

  test 'associated_with? method' do
    assert @client2.associated_with? @booked_class
    refute @client.associated_with? @booked_class
  end

  test 'deletable? method' do
    # no purchase or account
    assert @client.deletable?
    # has purchase
    refute @client2.deletable?

    @account = Account.create(email: @client.email,
                              password: 'foobar',
                              password_confirmation: 'foobar',
                              ac_type: 'client')
    @client.update(account_id: @account.id)
    # has account but no purchase
    refute @client.deletable?
  end

  # test 'just_bought_groupex? method' do
  #   refute @client.just_bought_groupex?
  #   assert @client2.just_bought_groupex?
  # end

  test '#has_had_trial?' do
    refute @client.has_had_trial?
    refute @client2.has_had_trial?
    assert @client_trial1.has_had_trial?
    assert @client_trial2.has_had_trial?
  end

  test 'associated account (if there is one) should exist' do
    @client.account_id = 4000

    refute_predicate @client, :valid?
  end
end
