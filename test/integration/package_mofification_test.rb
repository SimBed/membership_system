require "test_helper"

class PackageMofificationTest < ActionDispatch::IntegrationTest
  def setup
    @admin = accounts(:admin)
    @purchase = purchases(:ekta_unlimited)
    @wkclass = wkclasses(:wkclass_for_booking_early)
    # @purchase_with_freeze = purchases(:purchase_for_freeze)
    @freeze = freezes(:freeze_test)
    @payment = payments(:payment1)
    travel_to(Date.parse('21 March 2022')) # day after class attended on this package
  end  

  test 'admin creates standard freeze' do
    orig_expiry_date = @purchase.expiry_date
    # make booking during intended freeze period to show it gets cancelled
    new_wkclass = @wkclass.dup
    new_wkclass.update(start_time: Time.zone.now.advance(days: 2, hours: 17))
    assert_difference '@purchase.attendances.no_amnesty.size', 1 do
      Attendance.create(wkclass_id: new_wkclass.id, purchase_id: @purchase.id, status: 'booked')
    end
    log_in_as(@admin)
    assert_difference -> { Freeze.count } => 1, -> { Payment.count } => 1, -> { @purchase.attendances.booked.size } => -1 do
      post admin_freezes_path, params:
       { freeze:
          { purchase_id: @purchase.id,
            start_date: Time.zone.tomorrow,
            end_date: Time.zone.tomorrow.advance(days: 6), #7 day freeze
            medical: false,
            doctor_note: false,
            payment_attributes:
              {dop: Time.zone.tomorrow,
               amount: 650,
               payment_mode: 'cheque'
              }
          }
        }
    end
    assert_equal orig_expiry_date.advance(days: 7), @purchase.reload.expiry_date
  end
  
  test 'admin creates medical freeze with doctors note' do
    log_in_as(@admin)
    assert_difference -> { Freeze.count } => 1, -> { Payment.count } => 0 do
      post admin_freezes_path, params:
      { freeze:
        { purchase_id: @purchase.id,
        start_date: Time.zone.tomorrow,
        end_date: Time.zone.tomorrow.advance(days: 6), #7 day freeze
        medical: true,
        doctor_note: true,
        payment_attributes:
          { dop: Time.zone.tomorrow,
            amount: 0,
            payment_mode: ''
          }
        }
      }
    end
  end

  #NOTE: implement new business logic to require a medical freeze with no doctor's not being accepted withouta non-nil (10 character min) freeze note
  test 'admin creates medical freeze without doctors note' do
    log_in_as(@admin)
    assert_difference -> { Freeze.count } => 1, -> { Payment.count } => 0 do
      post admin_freezes_path, params:
      { freeze:
        { purchase_id: @purchase.id,
          start_date: Time.zone.tomorrow,
          end_date: Time.zone.tomorrow.advance(days: 6), #7 day freeze
          medical: true,
          doctor_note: false,
          payment_attributes:
            { dop: Time.zone.tomorrow,
              amount: 0,
              payment_mode: ''
            }
        }
      }
    end
  end

  test 'admin creates restart' do
    orig_expiry_date = @purchase.expiry_date
    # make booking after intended restart date to show it gets cancelled
    new_wkclass = @wkclass.dup
    new_wkclass.update(start_time: Time.zone.now.advance(days: 2, hours: 17))
    assert_difference '@purchase.attendances.no_amnesty.size', 1 do
      Attendance.create(wkclass_id: new_wkclass.id, purchase_id: @purchase.id, status: 'booked')
    end    
    log_in_as(@admin)
    assert_difference -> { Restart.count } => 1, -> { Purchase.count } => 1, -> { Payment.count } => 1, -> { @purchase.attendances.booked.size } => -1 do
      post admin_restarts_path, params:
       { restart:
          { parent_id: @purchase.id,
            payment_attributes:
              {dop: Time.zone.tomorrow,
               amount: 1500,
               payment_mode: 'cash'
              }
          }
        }
    end
    restart = Restart.last
    restarted_purchase = Purchase.last
    assert_equal 'expired', @purchase.reload.status
    assert_equal Time.zone.tomorrow, @purchase.reload.expiry_date
    assert_equal @purchase.child_purchase, restarted_purchase
    assert_equal restarted_purchase.parent_purchase, @purchase
    assert_equal @purchase.restart_as_parent, restart
    assert_equal @purchase.child_purchase.restart_as_child, restart
    assert_equal restart.parent, @purchase 
    assert_equal restart.child, restarted_purchase
    assert_equal 'not started', restarted_purchase.status
  end  

  test 'admin updates freeze payment amount' do
    assert_equal 650, @payment.amount
    assert_equal @freeze.payment, @payment
    freeze = @freeze
    log_in_as(@admin)
      patch admin_freeze_path(@freeze), params:
      { freeze:
        { purchase_id: @freeze.purchase_id,
          start_date: @freeze.start_date,
          end_date: @freeze.end_date.advance(days:2),
          note: @freeze.note,
          medical: @freeze.medical,
          doctor_note: @freeze.doctor_note,
          added_by: @freeze.added_by,
          payment_attributes:
            { dop: @payment.dop,
              amount: 300,
              payment_mode: 'Google Pay',
              note: @payment.note
            }
        }
      }
    assert_equal 300, @freeze.reload.payment.amount
    assert_equal 'Google Pay', @freeze.payment.payment_mode
    assert_equal Date.parse('2021-10-19'), @freeze.end_date
  end
end