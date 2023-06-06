require 'test_helper'

class PartnerTest < ActiveSupport::TestCase
  def setup
    @partner = Partner.new(first_name: 'Apu',
                           last_name: 'Mathu',
                           email: 'apu@thespace.in',
                           account_id: accounts(:partner1).id)
  end

  test 'should be valid' do
    assert_predicate @partner, :valid?
  end

  test 'first name should be present' do
    @partner.first_name = '     '

    refute_predicate @partner, :valid?
  end

  test 'last name should be present' do
    @partner.last_name = '     '

    refute_predicate @partner, :valid?
  end

  test 'full name should be unique' do
    duplicate_named_partner = Partner.new(first_name: @partner.first_name, last_name: @partner.last_name)
    @partner.save

    refute_predicate duplicate_named_partner, :valid?
  end

  test 'associated account (if there is one) should exist' do
    @partner.account_id = 4000

    refute_predicate @partner, :valid?
  end
end
