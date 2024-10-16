class RenewalPresenter < BasePresenter

  def initialize(attributes)
    @renewal = attributes[:renewal]
    @product = attributes[:product] || @renewal.product
  end

  
  def base_price
    if @renewal.offer_online_discount?
      rupees(@renewal.base_price(@product).price)
    else
      nil
    end
  end
  
  def price
    rupees(@renewal.price @product)
  end
  
  def saving_html
    saving = @renewal.renewal_saving @product
    return nil if saving.zero?
    
    content_tag(:li, "Save #{rupees(saving)}")
  end
  
  def renewal_statement(renewable)
    return nil unless renewable
    
    ongoing = @renewal.package_ongoing?
    trial = @renewal.from_trial?
    valid = @renewal.valid?
    student_discount = @renewal.student_discount?
    
    # student
    return I18n.t('student', discount: format_rate(:student)) if student_discount
    
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
  
  def visit_shop_statement(rider)
    return "Visit the #{link_to 'Shop', client_shop_path(@renewal.client), class: 'like_button text-uppercase', data: {turbo: false}} now".html_safe unless rider
    
    "Visit the #{link_to 'Shop', client_shop_path(@renewal.client), class: 'like_button text-uppercase', data: {turbo: false}} for more group classes".html_safe
  end
  
  def shop_discount_statement
    return nil if !@renewal.offer_online_discount? || @renewal.new_client? # a new client gets its own special section so doesn't need this
    
    return 'Special Discount Applies' if @renewal.oneoff_discount?
    
    return "Buy your Package with a #{format_rate(:student)}% online student discount!" if @renewal.student_discount?
    
    return nil unless @renewal.offer_renewal_discount?
    case @renewal.renewal_situation
    when :renewal_pre_trial_expiry
      "Buy your first Package before your Trial expires with a #{format_rate(:renewal_pre_trial_expiry)}% online discount!"
    when :renewal_post_trial_expiry
      "Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!"
    when :renewal_pre_package_expiry
      "Renew your Package before expiry with a #{format_rate(:renewal_pre_package_expiry)}% online discount!"
    when :renewal_post_package_expiry
      "Renew your Package with a #{format_rate(:renewal_post_package_expiry)}% online discount!"
    end
  end

  def new_client_statement
    return "We offer a #{format_rate(:student)}% online discount for monthly Packages to full-time students" if @renewal.client.student?

    "On your first monthly package we offer a #{format_rate(:first_package)}% online discount!"    
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