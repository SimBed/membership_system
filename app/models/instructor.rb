class Instructor < ApplicationRecord
  has_many :wkclasses
  has_many :instructor_rates, dependent: :destroy
  scope :order_by_name, -> { order(:first_name, :last_name) }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :first_name, uniqueness: {scope: :last_name, message: "Already an instructor with this name"}

  def name
    "#{first_name} #{last_name}"
  end

  def current_rate
    instructor_rates.order_recent_first.first&.rate
  end
end
