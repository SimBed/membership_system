class Penalty < ApplicationRecord
  belongs_to :purchase
  belongs_to :booking
end
