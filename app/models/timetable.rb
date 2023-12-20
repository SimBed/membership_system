class Timetable < ApplicationRecord
  has_many  :table_times, dependent: :destroy
  has_many  :table_days, dependent: :destroy
  # has_many :entries, through: :table_times
  has_many :entries, through: :table_days
end
