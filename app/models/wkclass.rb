class Wkclass < ApplicationRecord
  has_many :attendances
  has_many :rel_user_products, through: :attendances
  has_many :users, through: :rel_user_products 
  belongs_to :workout

  def date
    start_time.strftime('%a %d %b %y')
  end

  def time
    start_time.strftime('%H:%M')
  end

  def summary
    "#{workout.name}, #{date}, #{time}"
  end
end
