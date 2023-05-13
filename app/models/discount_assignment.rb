class DiscountAssignment < ApplicationRecord
  belongs_to :discount
  belongs_to :purchase
end
