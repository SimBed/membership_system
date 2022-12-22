class InstructorRate < ApplicationRecord
  belongs_to :instructor
  scope :order_recent_first, -> { order(created_at: :desc) }
  scope :order_by_instructor, -> { joins(:instructor).order('first_name', 'date_from desc') }
  scope :order_by_current, -> { order(current: :desc) }
  scope :current, -> { where(current: true) }
end
