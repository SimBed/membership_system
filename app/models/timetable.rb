class Timetable < ApplicationRecord
  has_many  :table_times, dependent: :destroy
  has_many  :table_days, dependent: :destroy
  # has_many :entries, through: :table_times
  has_many :entries, through: :table_days
  scope :order_by_date_until, -> { order(date_until: :desc, created_at: :asc) }
  scope :overlapping, -> timetable { exclude(timetable.id).where("date_from <= ? AND ? <= date_until", timetable.date_until, timetable.date_from) }
  scope :current_at, ->date { where('DATE(?) BETWEEN date_from AND date_until', date).order(date_from: :desc) }
  scope :actives_at, ->date { current_at(date) }
  # scope :exclude_self, -> id { where.not(id: id) }

  class << self
    def display_entries(days: 7, show_publicly_invisible: false)
      entries_hash = {}
      # {Monday: [<Entry:0x00007f1...>, <Entry:0x....], Tuesday: [....], ....}      
      start_date = Time.zone.now.to_date
      (start_date..start_date.advance(days: days - 1)).each do |date|
        timetable = Timetable.actives_at(date).first
        day_of_week = date.strftime("%A").capitalize
        table_day = TableDay.for_day_of_week(timetable, day_of_week)
        if table_day.nil?
          entries_hash[day_of_week] = nil
        else
          entries = table_day.entries.order_by_start
          # NOTE: improve with #then https://stackoverflow.com/questions/1797189/conditional-chaining-in-ruby
          entries_hash[day_of_week] = show_publicly_invisible ? entries.includes(:table_time, :workout) : entries.publicly_visible.includes(:table_time, :workout)
        end 
      end
      entries_hash
    end
  end
end