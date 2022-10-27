class TableTime < ApplicationRecord
  belongs_to :timetable
  has_many  :entries
end
