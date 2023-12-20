module ApplyDiscount
  extend ActiveSupport::Concern

  included do
    def apply_discount(base_price, *discounts)
      discount = { percent: 0, fixed: 0 }
      unless discounts.empty?
        discount[:percent] = discounts.map { |d| d&.percent }.compact.inject(:+)
        discount[:fixed] = discounts.map { |d| d&.fixed }.compact.inject(:+)
      end
      unrounded = ((base_price.price * (1 - (discount[:percent].to_f / 100))) - discount[:fixed])
      # dont want a 0% discount to result in a different price to the base price
      return base_price.price if unrounded.round(0) == base_price.price.round(0)

      # dont want the artificial 'Price Change Transition' discounts to result in a different price to the one paid
      return unrounded.round(0) if discounts.map { |d| d.name[0..22] }.include? 'Price Change Transition'

      up_to_nearest50([0, unrounded.round(0)].max)
    end
  end

  # courtesy engineersmnky https://stackoverflow.com/questions/51274453/ruby-round-integer-to-nearest-multiple-of-5
  def up_to_nearest50(n)
    return n if (n % 50).zero?

    rounded = n.round(-2)
    rounded > n ? rounded : rounded + 50
  end
end
