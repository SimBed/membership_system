class Waiting < ApplicationRecord
  belongs_to :wkclass
  belongs_to :purchase
  scope :order_by_created, -> { order(:created_at) }
end
