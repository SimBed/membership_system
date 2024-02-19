class Restart < ApplicationRecord
  # belongs_to :purchase
  belongs_to :parent, class_name: "Purchase"
  belongs_to :child, class_name: "Purchase", optional: true # not optional but easier for now to set child_id after establishing the restart in RestartsController#create
  has_one :payment, as: :payable, dependent: :destroy
  accepts_nested_attributes_for :payment  
  scope :order_by_dop, -> { joins(:payment).order(dop: :desc) }
end
