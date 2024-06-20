class Fitternity < ApplicationRecord
  has_many :purchases, dependent: nil
  has_many :bookings, through: :purchases
  scope :ongoing, -> { all.reject(&:expired?) }

  def started?
    !purchases.nil?
  end

  def maxed_classes?
    purchases.size == max_classes
  end

  def past_expiry?
    Time.zone.today > expiry_date
  end

  def expired?
    maxed_classes? || past_expiry?
  end

  def classes_remain(provisional: true)
    return (max_classes - bookings.no_amnesty.size) if provisional

    max_classes - bookings.confirmed.no_amnesty.size
  end
end
