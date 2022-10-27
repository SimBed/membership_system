class Timetable < ApplicationRecord
  has_many  :table_times
  has_many  :table_days
  has_many :entries, through: :table_times
  has_many :entries, through: :table_days  
end
