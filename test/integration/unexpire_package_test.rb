require 'test_helper'

class UnexpirePackageTest < ActionDispatch::IntegrationTest
  setup do
    @admin = accounts(:admin)
    @purchase = purchases(:purchase_for_freeze)
  end

  test 'package expired due to validity should revert to ongoing with a suitable freeze' do
    travel_to(Date.parse('May 9 2022').beginning_of_day)
    # start with 8 class expired package with 1 10 day freeze
    assert_equal 7, @purchase.attendances.size
    assert_equal 10, @purchase.freezes.map(&:duration).inject(0, :+)
    assert_equal Date.parse('Nov 20 2021'), @purchase.expiry_date
    assert_equal 'expired', @purchase.status

    # give long freeze
    log_in_as(@admin)
    post freezes_path, params:
     { freeze:
        { purchase_id: @purchase.id,
          start_date: '2021-11-17',
          end_date: '2022-05-05' } }

    # freeze unexpires
    assert_equal 180, @purchase.reload.freezes.map(&:duration).inject(0, :+)
    assert_equal Date.parse('May 9 2022'), @purchase.expiry_date
    assert_equal 'ongoing', @purchase.status
    # will expire again
    travel_to(Date.parse('May 11 2022').beginning_of_day)
    @purchase.update(status: @purchase.status_calc)

    assert_equal 'expired', @purchase.reload.status
  end
end
