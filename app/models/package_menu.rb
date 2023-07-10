class PackageMenu
  include ApplyDiscount
  def initialize()
  end

  def price(product)
    apply_discount(product.base_price_at(Time.zone.now), Discount.with_renewal_rationale_at('first_package', Time.zone.now)&.first)
  end

  def base_price(product)
    product.base_price_at(Time.zone.now).price
  end

  def discount(product)
    return nil if base_price(product) == price(product)

    base_price(product) - price(product)
  end

end
