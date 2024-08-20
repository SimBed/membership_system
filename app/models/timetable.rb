class Timetable < ApplicationRecord
  has_many  :table_times, dependent: :destroy
  has_many  :table_days, dependent: :destroy
  # has_many :entries, through: :table_times
  has_many :entries, through: :table_days
  scope :order_by_date_until, -> { order(date_until: :desc, created_at: :asc) }
  scope :overlapping, -> timetable { exclude(timetable.id).where("date_from <= ? AND ? <= date_until", timetable.date_until, timetable.date_from) }
  scope :current_at, ->date { where('DATE(?) BETWEEN date_from AND date_until', date).order(date_from: :desc) }
  scope :active_at, ->date { current_at(date).first }
  # scope :exclude_self, -> id { where.not(id: id) }
end