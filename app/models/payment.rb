class Payment < ApplicationRecord
  # once all exisitng payables have an associated payment, optional can be removed.
  belongs_to :payable, polymorphic: true, optional: true
  scope :order_by_dop, -> { order(dop: :desc) }
end
