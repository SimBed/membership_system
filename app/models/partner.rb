class Partner < ApplicationRecord
  has_many :workout_groups
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :first_name, uniqueness: {scope: :last_name, message: "Already a partner with this name"}

  def name
    "#{first_name} #{last_name}"
  end

  def workout_group_list
    workout_groups.pluck(:name).join(', ')
  end
end
