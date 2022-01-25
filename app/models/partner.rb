class Partner < ApplicationRecord
  has_many :workout_groups

  def name
    "#{first_name} #{last_name}"
  end

  def workout_group_list
    workout_groups.pluck(:name).join(', ')
  end
end
