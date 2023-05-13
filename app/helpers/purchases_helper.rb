module PurchasesHelper
  def discount(base_price, *discounts)
    discounts.each do |discount|
      base_price = base_price * (1 - discount.percent.to_f / 100) - (discount.fixed || 0)
    end
    base_price
  end  
end
