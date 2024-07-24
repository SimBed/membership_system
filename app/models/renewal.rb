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

  def best_discount
    # for now max 1 discount can apply and the one that applies is the one with the biggest percent
    renewal_discount = Discount.with_renewal_rationale_at(renewal_situation, Time.zone.now)&.first
    student_discount = Discount.student_at(Time.zone.now)&.first if @client.student?
    # too many variations apply
    # friends_and_family_discount = Discount.friends_and_family_at(Time.zone.now)&.first if @client.friends_and_family?
    oneoff_discount = Discount.with_rationale_at('Oneoff', Time.zone.now)&.first
    [renewal_discount, student_discount, oneoff_discount].compact.max_by { |d| [d.percent, d.fixed] }
  end

  def discount_hash
    # hash = { renewal: nil, status: nil, oneoff: nil }
    discount_applies = best_discount
    hash = Hash.new
    hash[discount_applies.discount_reason.rationale.downcase.to_sym] = discount_applies unless discount_applies.nil?
    hash

    # NOTE: nil.to_i returns 0
    # status_discount = (student_discount.percent.to_i > friends_and_family_discount.percent.to_i ? student_discount : friends_and_family_discount)
    # { renewal: Discount.with_renewal_rationale_at(renewal_situation, Time.zone.now)&.first,
    #   status: nil, status_discount,
    #   oneoff: Discount.with_rationale_at('Oneoff', Time.zone.now)&.first }
  end

  # def renewal_offer

  def oneoff_discount?
    return true unless discount_hash[:oneoff].nil?

    false
  end

  def new_client?
    return true if @groupex_package_purchases.empty?

    false
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

    false
  end

  def renewal_situation
    return :first_package if new_client?
    return :renewal_post_trial_expiry if expired_trial?
    return :renewal_post_package_expiry if expired_package?
    return :renewal_pre_trial_expiry if ongoing_trial?

    :renewal_pre_package_expiry # ongoing package
  end

  def offer_online_discount?
    return false if discount_hash.values.map(&:nil?).all?

    true
  end

  def offer_renewal_discount?
    return true if discount_hash.values.map(&:renewal_rationale?).any?

    true
  end

  def price(product)
    return base_price(product).price if product.trial?

    apply_discount(product.base_price_at(Time.zone.now), *discount_hash.values.compact)
  end

  def base_price(product)
    product.base_price_at(Time.zone.now)
  end

  def renewal_saving(product)
    base_product_price = base_price(product).price
    return 0 unless base_product_price

    base_product_price - price(product)
  end

  def valid?
    return false if new_client?
    return false if base_price(product).nil?

    true
  end

  def alert_to_renew?
    return false if new_client?
    return true unless package_ongoing?

    @client.alert_to_renew?
  end

  def package_ongoing?
    return true if @ongoing_groupex_package_purchases.any?

    false
  end

  def from_trial?
    return true if @last_groupex_package_purchase&.trial?

    false
  end

  def product
    return Product.trial.space_group.first if new_client?
    return @default_package if from_trial?

    @last_product
  end

  def default_class_number_type
    product.fixed_package? ? 'fixed' : 'unlimited'
  end
  
end
