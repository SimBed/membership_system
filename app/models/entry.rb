class Entry < ApplicationRecord
  belongs_to :table_time
  belongs_to :table_day
  belongs_to :workout
  delegate :name, to: :workout
  scope :order_by_start, -> { joins(:table_time).order(:start) }
  # avoid open gym showing in public timetable
  scope :publicly_invisible, -> { joins(:workout).where(workouts: {public_timetable_visible: false}) }
  scope :publicly_visible, -> { joins(:workout).where(workouts: {public_timetable_visible: true}) }
end