class Login < ApplicationRecord
  belongs_to :account
  scope :order_by_recent_first, -> { order(created_at: :desc) }
end
