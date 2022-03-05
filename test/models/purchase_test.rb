require "test_helper"

class PurchaseTest < ActiveSupport::TestCase
  def setup
    @purchase =
      Purchase.new(client_id: ActiveRecord::FixtureSet.identify(:Aparna),
                   product_id: ActiveRecord::FixtureSet.identify(:space_package),
                   payment: 10000,
                   dop: '2022-02-15',
                   payment_mode: 'Cash',
                   # invoice: '',
                   # adjust_restart: false,
                   expired: false,
                   price_id: ActiveRecord::FixtureSet.identify(:one)
                 )
end

  test 'should be valid' do
    assert @purchase.valid?
  end
end
