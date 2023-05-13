require 'test_helper'

class RenewalTest < ActiveSupport::TestCase
  def setup
    @client_package_ongoing_unlimited = clients(:bhavik) # 1 expired, 1 ongoing 3month unlimited group with freezes
    @client_package_expired_unlimited = clients(:client_package_expired) #["Group UC:1M", "Group UC:1M", "Group 6C:5W", "Group 6C:5W", "Group 6C:5W"]
    # @client_ekta_unlimited = clients(:client_ekta_unlimited) #[["ongoing", "Group", false], ["not yet started", "Nutrition", false], ["expired", "Group", false], ["expired", "Group", false]]
    @client_package_ongoing_fixed = clients(:client_fixed) #"Group 13C:120D"
    @new_client = clients(:new_client) #[]
    @client_trial_expired = clients(:client_trial_expired)
    @client_trial_ongoing = clients(:client_trial_ongoing)

    @renewal_package_ongoing_unlimited = Renewal.new(@client_package_ongoing_unlimited)
    @renewal_package_expired_unlimited = Renewal.new(@client_package_expired_unlimited)
    @renewal_package_ongoing_fixed = Renewal.new(@client_package_ongoing_fixed)
    @renewal_new_client = Renewal.new(@new_client)
    @renewal_trial_expired = Renewal.new(@client_trial_expired)
    @renewal_trial_ongoing = Renewal.new(@client_trial_ongoing)
    # note the purchsaes haven't been updated. Better testing would be to travel to a a date consistent with the test packages and update them
    # travel_to(Date.parse('20 April 2022'))
  end

  test '#new_client?' do
    refute @renewal_package_ongoing_unlimited.new_client?
    refute @renewal_package_expired_unlimited.new_client?
    refute @renewal_package_ongoing_fixed.new_client?
    assert @renewal_new_client.new_client?
    refute @renewal_trial_expired.new_client?
    refute @renewal_trial_ongoing.new_client?
  end
  test '#expired_trial?' do
    refute @renewal_package_ongoing_unlimited.expired_trial?
    refute @renewal_package_expired_unlimited.expired_trial?
    refute @renewal_package_ongoing_fixed.expired_trial?
    refute @renewal_new_client.expired_trial?
    assert @renewal_trial_expired.expired_trial?
    refute @renewal_trial_ongoing.expired_trial?
  end
  test '#expired_package?' do
    refute @renewal_package_ongoing_unlimited.expired_package?
    assert @renewal_package_expired_unlimited.expired_package?
    refute @renewal_package_ongoing_fixed.expired_package?
    refute @renewal_new_client.expired_package?
    refute @renewal_trial_expired.expired_package?
    refute @renewal_trial_ongoing.expired_package?
  end
  test '#ongoing_trial?' do
    refute @renewal_package_ongoing_unlimited.ongoing_trial?
    refute @renewal_package_expired_unlimited.ongoing_trial?
    refute @renewal_package_ongoing_fixed.ongoing_trial?
    refute @renewal_new_client.ongoing_trial?
    refute @renewal_trial_expired.ongoing_trial?
    assert @renewal_trial_ongoing.ongoing_trial?
  end
  test '#discount' do
    assert_equal 1250, @renewal_package_ongoing_unlimited.discount(@renewal_package_ongoing_unlimited.product)
    assert_nil @renewal_package_expired_unlimited.discount(@renewal_package_expired_unlimited.product)
    assert_equal 600, @renewal_package_ongoing_fixed.discount(@renewal_package_ongoing_fixed.product)
    assert_nil @renewal_new_client.discount(@renewal_new_client.product)
    assert_equal 3800, @renewal_trial_expired.discount(@renewal_trial_expired.product)
    assert_equal 5100, @renewal_trial_ongoing.discount(@renewal_trial_ongoing.product)
  end
  test '#alert_to_renew?' do
  assert @renewal_package_ongoing_unlimited.alert_to_renew?
  assert @renewal_package_expired_unlimited.alert_to_renew?
  assert @renewal_package_ongoing_fixed.alert_to_renew?
  refute @renewal_new_client.alert_to_renew?
  assert @renewal_trial_expired.alert_to_renew?
  assert @renewal_trial_ongoing.alert_to_renew?
  # ensure the the client's ongoing purchase is close to expiry
  travel_to(Date.parse('20 April 2022'))
  Setting.days_remain = 7
  refute @renewal_package_ongoing_unlimited.alert_to_renew?
  end
  test '#valid?' do
    assert @renewal_package_ongoing_unlimited.valid?
    assert @renewal_package_expired_unlimited.valid?
    assert @renewal_package_ongoing_fixed.valid?
    assert_nil @renewal_new_client.valid?
    assert @renewal_trial_expired.valid?
    assert @renewal_trial_ongoing.valid?
    # destroy base price of client's ongoing product so renewal no longer valid
    @client_package_ongoing_unlimited.purchases.last.product.base_price_at(Time.zone.now).destroy
    refute @renewal_package_ongoing_unlimited.valid?
  end
  test '#base_price' do
    assert_equal prices(:Uc3mbase), @renewal_package_ongoing_unlimited.base_price(@renewal_package_ongoing_unlimited.product)
    assert_equal prices(:Uc1mbase), @renewal_package_expired_unlimited.base_price(@renewal_package_expired_unlimited.product)
    assert_equal prices(:fixed_base), @renewal_package_ongoing_fixed.base_price(@renewal_package_ongoing_fixed.product)
    assert_equal prices(:trial), @renewal_new_client.base_price(@renewal_new_client.product)
    assert_equal prices(:Uc3mbase), @renewal_trial_expired.base_price(@renewal_trial_expired.product)
    assert_equal prices(:Uc3mbase), @renewal_trial_ongoing.base_price(@renewal_trial_ongoing.product)
  end  
  test '#price' do
    assert_equal 24250, @renewal_package_ongoing_unlimited.price(@renewal_package_ongoing_unlimited.product)
    assert_equal 9500, @renewal_package_expired_unlimited.price(@renewal_package_expired_unlimited.product)
    assert_equal 11750, @renewal_package_ongoing_fixed.price(@renewal_package_ongoing_fixed.product)
    assert_equal 1500, @renewal_new_client.price(@renewal_new_client.product)
    assert_equal 21700, @renewal_trial_expired.price(@renewal_trial_expired.product)
    assert_equal 20400, @renewal_trial_ongoing.price(@renewal_trial_ongoing.product)
  end  
  test '#renewal_offer' do
    assert_equal "renewal_pre_package_expiry", @renewal_package_ongoing_unlimited.renewal_offer
    assert_equal "renewal_post_package_expiry", @renewal_package_expired_unlimited.renewal_offer
    assert_equal "renewal_pre_package_expiry", @renewal_package_ongoing_fixed.renewal_offer
    assert_equal "first_package", @renewal_new_client.renewal_offer
    assert_equal "renewal_post_trial_expiry", @renewal_trial_expired.renewal_offer
    assert_equal "renewal_pre_trial_expiry", @renewal_trial_ongoing.renewal_offer
  end  
  test '#offer_online_discount?' do
    assert @renewal_package_ongoing_unlimited.offer_online_discount?
    refute @renewal_package_expired_unlimited.offer_online_discount?
    assert @renewal_package_ongoing_fixed.offer_online_discount?
    assert @renewal_new_client.offer_online_discount?
    assert @renewal_trial_expired.offer_online_discount?
    assert @renewal_trial_ongoing.offer_online_discount?
  end  
end
