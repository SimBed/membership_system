class Instructor < ApplicationRecord
  has_many :workouts, dependent: :destroy
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :first_name, uniqueness: {scope: :last_name, message: "Already an instructor with this name"}

  def name
    "#{first_name} #{last_name}"
  end
end
