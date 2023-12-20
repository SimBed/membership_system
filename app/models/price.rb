class Price < ApplicationRecord
  belongs_to :product
  validates :date_from, presence: true, allow_blank: false
  validates :date_until, presence: true, allow_blank: false
  validates :price, presence: true, numericality: { only_integer: true }
  # in case an old price is not retired, there may be multiple prices retireved, in which case we should use the one with the most recent date_from
  scope :base_at, ->(date) { where('DATE(?) BETWEEN date_from AND date_until', date).order(date_from: :desc) }

  def current?
    Time.zone.now.between?(date_from, date_until)
  end

  # courtesy engineersmnky https://stackoverflow.com/questions/51274453/ruby-round-integer-to-nearest-multiple-of-5
  # not used done on the browser in JS in the end
  def self.up_to_nearest50(n)
    return n if (n % 50).zero?

    rounded = n.round(-2)
    rounded > n ? rounded : rounded + 50
  end

  def pre_oct22_price?
    # nuances of old Price model:
    # Price's price used to be explicitly retained in the price field for each Price. The new design of the Price method calculate
    # the Price's price based on base price and discount.
    # percentage discounts were crudely calculated and input. The new design of the Price method calculates precisely and rounds up to nearest Rs.50
    return false if created_at.nil?

    return true if created_at < Date.new(2022, 10, 05)

    false
  end

  def deletable?
    return true if Purchase.where(price_id: id).empty?

    false
  end

  # def self.discount_format(price)
  #   # hack to access helpers in model
  #   # https://www.quora.com/How-do-I-use-helper-methods-in-models-in-rails
  #   ApplicationController.helpers.number_with_precision(price.discount, precision: 2,significant: false, strip_insignificant_zeros: true)
  # end
end
