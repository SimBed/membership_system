class Waiver < ApplicationRecord
  belongs_to :client
  scope :order_by_date, -> { order(:created_at) }
end
