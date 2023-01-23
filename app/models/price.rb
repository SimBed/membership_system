class Price < ApplicationRecord
  belongs_to :product
  validates :date_from, presence: true, allow_blank: false
  validates :name, presence: true
  # validates :price, presence: true, numericality: { only_integer: true }
  validate :current_base_check
  # redundant
  # scope :order_by_current_price, -> { order(current: :desc, price: :desc) }
  scope :order_by_current_discount, -> { order(current: :desc, discount: :asc) }
  scope :current, -> { where(current: true).order(price: :desc) }
  scope :base, -> { where(base: true) }
  # default_scope { order('prices.discount ASC') }
  default_scope -> { order(discount: :asc) }

  # courtesy engineersmnky https://stackoverflow.com/questions/51274453/ruby-round-integer-to-nearest-multiple-of-5
  # not used done on the browser in JS in the end
  def self.up_to_nearest_50(n)
    return n if n % 50 == 0
    rounded = n.round(-2)
    rounded > n ? rounded : rounded + 50
  end

  def base_price
    product.prices.current.base.first&.price
  end

  def discounted_price
    return price if base? || pre_oct22_price?
    return 0 if base_price.nil?

    raw_price = base_price * (1 - (discount.to_f / 100))
    Price.up_to_nearest_50(raw_price).to_i
  end

  def pre_oct22_price?
    # nuances of old Price model:
    # Price's price used to be explicitly retained in the price field for each Price. The new design of the Price method calculate
    # the Price's price based on base price and discount.
    # percentage discounts were crudely calculated and input. The new design of the Price method calculates precisely and rounds up to nearest Rs.50
    return false if created_at.nil?

    return true if created_at < Date.new(2022,10,05)

    return false
  end

  # def full_name
  #   # "#{name} #{discount}%".gsub(' 0%', '')
  #   "#{name} #{Price.discount_format(self)}%"
  # end
  #
  # def self.discount_format(price)
  #   # hack to access helpers in model
  #   # https://www.quora.com/How-do-I-use-helper-methods-in-models-in-rails
  #   ApplicationController.helpers.number_with_precision(price.discount, precision: 2,significant: false, strip_insignificant_zeros: true)
  # end

  private
  def current_base_check
    return unless base?

    current_base = product.prices.where(current: true, base: true).first
    return if current_base.blank?

    errors.add :base, 'there is already a curent, base price. Edit the existing curent, base price before adding a new curent, base price.' unless id == current_base.id
  end

end
