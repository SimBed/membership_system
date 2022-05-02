class Penalty < ApplicationRecord
  belongs_to :purchase
  belongs_to :attendance
end
