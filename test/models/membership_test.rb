require 'test_helper'
class MembershipTest < ActiveSupport::TestCase
  def setup
    travel_to Date.parse('2 April 2022') # mid second freeze
    @purchase_with_freezes = purchases(:purchase_with_freezes) # freeze 10/1/22 - 28/3/22 & 
    @membership = Membership.new(@purchase_with_freezes)
    @purchase_fixed = purchases(:tina8c5wong)
    @membership_fixed = Membership.new(@purchase_fixed)
  end

  test '#days_passed' do
    # start date 11/2021
    assert_equal 143, @membership.days_passed
  end

  test '#days_frozen' do
    # 77 days (first freeze) + 2 days (second freeze)
    assert_equal 79, @membership.days_frozen
  end

  test '#active_membership' do
    # 143 days passes - 79 days frozen 
    assert_equal 64, @membership.active_membership
  end

  test '#intended_membership' do
    # 2 day adjustment
    assert_equal 94, @membership.intended_membership
  end

  # test '#usage_charge' do
  #   assert_equal 13617, @membership.usage_charge
  # end

  # test '#price_change_charge' do
  #   assert_equal 5500, @membership.price_change_charge
  # end

  test '#transfer_charge for unlimited' do
    assert_equal 21617, @membership.transfer_charge
  end
  
  test '#transfer_charge for fixed' do
    assert_equal 7000, @membership_fixed.transfer_charge
  end

end