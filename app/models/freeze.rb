class Freeze < ApplicationRecord
  belongs_to :purchase

  def duration
    # (end_date - start_date + 1.days).to_i #Date - Date returns a rational
    (self.start_date...self.end_date).count
  end
end
