class RenewalPresenter < BasePresenter

  def initialize(attributes = {})
    @renewal = attributes[:renewal]
    @product = attributes[:product]
  end

  def base_price_html
    if @renewal.offer_online_discount?
      content_tag :div, rupees(@renewal.base_price(@product).price), class: %w[pe2, base-price]
    else
      nil
    end
  end

  def price_html
    content_tag :div, rupees(@renewal.price(@product)), class: %w[pe2, discount-price]
  end

  def saving_html
    saving = @renewal.renewal_saving(@product)
    return nil if saving.nil?

    content_tag(:li, "Save #{rupees(saving)}")
  end

  private

  def rupees(amount)
    number_to_currency(amount, precision: 0, unit: 'Rs. ')
  end
  
end