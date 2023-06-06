class TableTime < ApplicationRecord
  belongs_to :timetable
  has_many :entries, dependent: :destroy
  scope :order_by_time, -> { order(:start) }
  scope :during, ->(time_of_day) { where({ start: period(time_of_day) }) }

  def self.period(time_of_day)
    # start_time is stored as type time (as eg 10:00:00 with no date) but ActiveRecord somehow defaults the date to 1 Jan 2000 in the time object when retrieved
    t0 = Time.parse('1 Jan 2000').beginning_of_day
    return t0...t0.midday if time_of_day == 'morning'
    return t0.midday..t0.change(hour: 17, min: 59) if time_of_day == 'afternoon'

    t0.change(hour: 18)..t0.end_of_day
  end
end
