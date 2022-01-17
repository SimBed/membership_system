class Fitternity < ApplicationRecord
  has_many :purchases
  has_many :attendances, through: :purchases
  scope :ongoing, -> { all.select { |f| !(f.expired?) }}

  def started?
    !purchases.nil?
  end

  def maxed_classes?
    purchases.size == max_classes
  end

  def past_expiry?
    Date.today() > expiry_date
  end

  def expired?
    maxed_classes? || past_expiry?
  end

  def classes_remain
    max_classes - purchases.size
  end

end