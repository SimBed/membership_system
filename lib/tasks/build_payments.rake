desc 'build a payment for each purchase'
task payment_build: :environment do
  Purchase.left_joins(:payment).where(payments: {payable_type:nil}).each do |p|
    # no payment needed for restarted purchases. payment is associated with the parent purchase and the restart model
    p.build_payment(amount: p.charge, payment_mode: p.payment_mode, dop: p.dop).save unless p.parent_purchase
  end
end
