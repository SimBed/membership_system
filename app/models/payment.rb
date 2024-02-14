class Payment < ApplicationRecord
  # once all exisitng payables have an associated payment, optional can be removed.
  belongs_to :payable, polymorphic: true, optional: true
end
