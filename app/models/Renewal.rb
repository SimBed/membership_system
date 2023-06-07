class Renewal
  include ApplyDiscount
  def initialize(client)
    @client = client
    # does @groupex_package_purchases need to be an instance variable?
    @groupex_package_purchases = client.purchases.package.order_by_dop.renewable.includes(:product)
    @ongoing_groupex_package_purchases = @groupex_package_purchases.reject(&:expired?)
    @last_groupex_package_purchase = @groupex_package_purchases.first # @groupex_package_purchases is sorted by dop descending ie most recently purchased is first
    @last_product = @last_groupex_package_purchase&.product
    @default_package = Product.where(max_classes: 1000, validity_length: 3, validity_unit: 'M').first
  end
  attr_reader :last_product, :client

  def discount_hash
    # for now quick and dirty, max 1 discount can apply and the one that applies is the one with the biggest percent
    renewal_discount = Discount.with_renewal_rationale_at(renewal_offer, Time.zone.now)&.first
    student_discount = Discount.student_at(Time.zone.now)&.first if @client.student?
    friends_and_family_discount = Discount.friends_and_family_at(Time.zone.now)&.first if @client.friends_and_family?
    oneoff_discount = Discount.with_rationale_at('Oneoff', Time.zone.now)&.first
    best_discount = [renewal_discount, student_discount, friends_and_family_discount, oneoff_discount].compact.sort_by { |d| [d.percent, d.fixed] }.last
    hash = { renewal: nil, status: nil, oneoff: nil }
    hash[best_discount.discount_reason.rationale.downcase.to_sym] = best_discount unless best_discount.nil?
    hash

    # NOTE: nil.to_i returns 0
    # status_discount = (student_discount.percent.to_i > friends_and_family_discount.percent.to_i ? student_discount : friends_and_family_discount)
    # { renewal: Discount.with_renewal_rationale_at(renewal_offer, Time.zone.now)&.first,
    #   status: nil, status_discount,
    #   oneoff: Discount.with_rationale_at('Oneoff', Time.zone.now)&.first }
  end

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
    # return "renewal_posttrial_expiry" if new_client? #need a new client rate setting
    return 'first_package' if new_client?
    return 'renewal_post_trial_expiry' if expired_trial?
    # return "base" if expired_package?
    return 'renewal_post_package_expiry' if expired_package?
    return 'renewal_pre_trial_expiry' if ongoing_trial?

    # "renewal_pre_expiry"  # ongoing package
    'renewal_pre_package_expiry' # ongoing package
  end

  def offer_online_discount?
    return false if discount_hash.values.map(&:nil?).all?

		  true
	end

  def price(product)
    # return nil if new_client?
    return base_price(product).price if product.trial?

    apply_discount(product.base_price_at(Time.zone.now), *discount_hash.values.compact)
  end

  def base_price(product)
    product.base_price_at(Time.zone.now)
  end

  # unused I think  / renewal_saving used in view (from clients_helper). make consistent and delete unused one
  def discount(product)
    return nil if new_client? || !valid? || base_price(self.product).price == price(self.product)

    base_price(self.product).price - price(self.product)
  end

  def valid?
    return nil if new_client?
    return false if base_price(product).nil?

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
    return Product.trial.space_group.first if new_client?
    return @default_package if from_trial?

    @last_product
  end
end
