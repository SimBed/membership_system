class Instructor < ApplicationRecord
  has_many :workouts
  def name
    "#{first_name} #{last_name}"
  end
end
