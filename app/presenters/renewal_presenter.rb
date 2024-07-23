class RenewalPresenter < BasePresenter

  def initialize(attributes)
    @renewal = attributes[:renewal]
    @product = attributes[:product] || @renewal.product
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
    return nil if saving.zero?

    content_tag(:li, "Save #{rupees(saving)}")
  end

  def renewal_statement(renewable)
    return nil unless renewable

    ongoing = @renewal.package_ongoing?
    trial = @renewal.from_trial?
    valid = @renewal.valid?
    
    # ongoing trial
    return I18n.t('renewal_pre_trial_expiry', discount: format_rate(:renewal_pre_trial_expiry)) if ongoing && trial

    # ongoing package
    return I18n.t('renewal_pre_package_expiry', discount: format_rate(:renewal_pre_package_expiry)) if ongoing && !trial && valid

    # ongoing package but price not listed for current product (rare)
    return I18n.t('renewal_alt_pre_package_expiry', discount: format_rate(:renewal_pre_package_expiry)) if ongoing && !trial && !valid
    
    # expired trial
    return I18n.t('renewal_post_trial_expiry', discount: format_rate(:renewal_post_trial_expiry)) if !ongoing && trial

    # expired package
    return I18n.t('renewal_post_package_expiry')

    rescue
      nil
  end

  def product_name
    @product.name(verbose: true)
  end  

  private

  def rupees(amount)
    number_to_currency(amount, precision: 0, unit: 'Rs. ')
  end

  def format_rate(renewal_type)
    number_with_precision(Discount.rate(Time.zone.now.to_date)[renewal_type][:percent], strip_insignificant_zeros: true)
  end  
  
end