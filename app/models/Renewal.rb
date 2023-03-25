class Renewal
  def initialize(client)
    @client = client
    @groupex_package_purchases = client.purchases.package.order_by_dop.renewable
    @ongoing_groupex_package_purchases = @groupex_package_purchases.reject(&:expired?)
    @last_groupex_package_purchase = @groupex_package_purchases.first # @groupex_package_purchases is sorted by dop descending ie most recently purchased is first
    @default_package = Product.where(max_classes: 1000, validity_length: 3, validity_unit: 'M').first
    @last_product = @last_groupex_package_purchase&.product
  end
  attr_reader :last_product

  def new_client?
    return true if @groupex_package_purchases.empty?

    return false
  end

  def expired_trial?
    return true if from_trial? && !package_ongoing?

    false
  end

  def expired_package?
    return false if new_client? || from_trial? || package_ongoing?

    true
  end

  def ongoing_trial?
    return true if from_trial? && package_ongoing?

    return false
  end

  def renewal_offer
    return "renewal_posttrial_expiry" if new_client? #need a new client rate setting
    return "renewal_posttrial_expiry" if expired_trial?   
    return "base" if expired_package?
    return "renewal_pretrial_expiry" if ongoing_trial?

    "renewal_pre_expiry"  # ongoing package
  end
  
  def offer_online_discount?
		return false if expired_package?

		true
	end

  def price
    return nil if new_client?

    product.renewal_price(renewal_offer)
  end

  def base_price
    return nil if new_client?
    return @default_package.renewal_price("base") if from_trial?

    product.renewal_price("base")
  end

  def discount
    return nil if new_client? || !valid? || base_price.price == price.price

    base_price.price - price.price
  end

  def valid?
    return nil if new_client?
    return false if price.nil? || base_price.nil?

    true
  end

  def alert_to_renew?
    return nil if new_client?
    return true unless package_ongoing?

    @client.alert_to_renew?
  end

  def package_ongoing?
    return true if @ongoing_groupex_package_purchases.any?

    return false
  end

  def from_trial?
    return true if @last_groupex_package_purchase&.trial?

    return false
  end

  def product 
    return nil if new_client?
    return @default_package if from_trial?

    @last_product
  end    

end