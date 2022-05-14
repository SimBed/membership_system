class Freeze < ApplicationRecord
  belongs_to :purchase
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :duration_length

  def duration
    # (end_date - start_date + 1.days).to_i #Date - Date returns a rational
    # .. inclusive, ... exclusive
    (self.start_date..self.end_date).count
  end

  private

  def duration_length
    errors.add(:base, 'must be 5 days or more') if duration < 5
  end
end
