class Payment < ApplicationRecord
  # once all exisitng payables have an associated payment, optional can be removed.
  belongs_to :payable, polymorphic: true, optional: true
  scope :order_by_dop, -> { order(dop: :desc) }
  scope :payable_types, ->(payable_types) { where(payable_type: payable_types) }
  scope :during, ->(period) { where(dop: period) }
  # try https://stackoverflow.com/questions/6399058/order-by-polymorphic-belongs-to-attribute
  # scope :order_by_client_name, -> { }
  scope :recover_order, ->(ids) { where(id: ids).order(Arel.sql("POSITION(id::TEXT IN '#{ids.join(',')}')")) }  
end
