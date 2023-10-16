class Freeze < ApplicationRecord
  belongs_to :purchase
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :duration_length
  # validate :no_attendance_during

  def duration
    # (end_date - start_date + 1.days).to_i #Date - Date returns a rational
    # .. inclusive, ... exclusive
    (start_date..end_date).count
  end

  # use for manually automating bulk freezes over holidays
  def applies_during(period)
    (start_date..end_date).overlaps?(period)
  end

  def days_frozen
    return 0 if Time.zone.now < start_date

    return (end_date - start_date + 1).to_i if Time.zone.now > end_date

    (Time.zone.now.to_date - start_date).to_i
  end

  private

  def duration_length
    errors.add(:base, 'must be 3 days or more') if duration < Setting.freeze_min_duration
  end

  # def no_attendance_during
  #   # purchases is only nil when we force it to be during tests
  #   return if purchase.nil?

  #   purchase.attendances.each do |a|
  #     errors.add(:base, 'bookings already during freeze period') and break if (start_date..end_date).cover?(a.wkclass.start_time)
  #   end
  # end
end
