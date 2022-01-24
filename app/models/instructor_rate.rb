class InstructorRate < ApplicationRecord
  belongs_to :instructor
  scope :order_recent_first, -> { order(created_at: :desc) }
end
