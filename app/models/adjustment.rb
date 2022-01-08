class Adjustment < ApplicationRecord
  belongs_to :purchase
  validates :adjustment, numericality: { only_integer: true }
end
