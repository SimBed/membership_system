require "test_helper"

class PartnerTest < ActiveSupport::TestCase
  def setup
    @partner = Partner.new(first_name: 'Apu',
                           last_name: 'Mathu',
                           email: 'apu@thespace.in',
                           account_id: ActiveRecord::FixtureSet.identify(:partner1)
                          )
  end

  test 'should be valid' do
    assert @partner.valid?
  end

  test 'first name should be present' do
    @partner.first_name = '     '
    refute @partner.valid?
  end

  test 'last name should be present' do
    @partner.last_name = '     '
    refute @partner.valid?
  end

  test 'full name should be unique' do
    duplicate_named_partner = Partner.new(first_name: @partner.first_name, last_name: @partner.last_name)
    @partner.save
    refute duplicate_named_partner.valid?
  end

  test 'associated account (if there is one) should exist' do
    @partner.account_id = 21
    refute @partner.valid?
  end
end
