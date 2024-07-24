require 'test_helper'

class RenewalPresenterTest < ActiveSupport::TestCase
  def setup
    @client_package_ongoing_unlimited = clients(:bhavik) # 1 expired, 1 ongoing 3month unlimited group with freezes
    @client_package_expired_unlimited = clients(:client_package_expired) # ["Group UC:1M", "Group UC:1M", "Group 6C:5W", "Group 6C:5W", "Group 6C:5W"]
    @client_package_ongoing_fixed = clients(:client_fixed) # "Group 13C:120D"
    @new_client = clients(:new_client) # []
    @client_trial_expired = clients(:client_trial_expired)
    @client_trial_ongoing = clients(:client_trial_ongoing)

    @rp_package_ongoing_unlimited = RenewalPresenter.new(renewal: Renewal.new(@client_package_ongoing_unlimited))
    @rp_package_expired_unlimited = RenewalPresenter.new(renewal: Renewal.new(@client_package_expired_unlimited))
    @rp_new_client = RenewalPresenter.new(renewal: Renewal.new(@new_client))
    @rp_trial_expired = RenewalPresenter.new(renewal: Renewal.new(@client_trial_expired))
    @rp_trial_ongoing = RenewalPresenter.new(renewal: Renewal.new(@client_trial_ongoing))
  end

  test '#shop_discount_statement' do
    assert_equal "Renew your Package before expiry with a 5% online discount!", @rp_package_ongoing_unlimited.shop_discount_statement
    assert_nil @rp_package_expired_unlimited.shop_discount_statement
    assert_nil @rp_new_client.shop_discount_statement
    assert_equal "Buy your first Package with a 15% online discount!", @rp_trial_expired.shop_discount_statement
    assert_equal "Buy your first Package before your Trial expires with a 20% online discount!", @rp_trial_ongoing.shop_discount_statement
  end
end
