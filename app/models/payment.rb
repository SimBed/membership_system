class Payment < ApplicationRecord
  # once all exisitng payables have an associated payment, optional can be removed.
  belongs_to :payable, polymorphic: true, optional: true
  scope :order_by_dop, -> { order(dop: :desc) }
  scope :payable_types, ->(payable_types) { where(payable_type: payable_types) }
  scope :during, ->(period) { where(dop: period) }
  scope :non_zero, -> { where.not(amount: 0) }
  scope :unpaid, -> { where(payment_mode: 'Not paid') }
  scope :written_off, -> { where(payment_mode: 'Write Off') }
  # try https://stackoverflow.com/questions/6399058/order-by-polymorphic-belongs-to-attribute
  # scope :order_by_client_name, -> { }
  scope :recover_order, ->(ids) { where(id: ids).order(Arel.sql("POSITION(id::TEXT IN '#{ids.join(',')}')")) }

  def purchase
    case payable_type
    when 'Purchase'
      payable
    when 'Freeze'
      payable.purchase
    when 'Restart'
      payable.parent
    end
  end
end
