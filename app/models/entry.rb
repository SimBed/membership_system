class Entry < ApplicationRecord
  belongs_to :table_time
  belongs_to :table_day
  belongs_to :workout
  scope :order_by_start, -> { joins(:table_time).order(:start) }
  # temporary hack to avoid showing on public timetable but continue to auto-create
  scope :open_gym, -> { joins(:workout).where(workouts: {name: 'Open Gym'}) }
  scope :not_open_gym, -> { joins(:workout).where.not(workouts: {name: 'Open Gym'}) }
end
