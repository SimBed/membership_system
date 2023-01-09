class Entry < ApplicationRecord
  belongs_to :table_time
  belongs_to :table_day
  scope :order_by_start, -> { joins(:table_time).order(:start) }
end
