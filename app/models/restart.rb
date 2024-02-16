class Restart < ApplicationRecord
  belongs_to :purchase
  has_one :payment, as: :payable, dependent: :destroy
  accepts_nested_attributes_for :payment  
  scope :order_by_dop, -> { joins(:payment).order(dop: :desc) }
end
