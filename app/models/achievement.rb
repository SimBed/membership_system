class Achievement < ApplicationRecord
  belongs_to :challenge
  belongs_to :client
  scope :order_by_date, -> { order(date: :desc) }
  scope :before, ->(date) { where('date <= ?', date) }
  validates :date, presence: true
  validates :score, presence: true, numericality: true
  # belongs_to already triggers validation error if associated record is not present
  # (but present is not the same as present and not nil as I discovered during tests)
  validates :challenge_id, presence: true  
  validates :client_id, presence: true  
end
