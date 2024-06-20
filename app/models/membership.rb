class Membership
  def initialize(purchase)
    @purchase = purchase
  end
  attr_reader :purchase

  def days_passed
    return 0 if @purchase.not_started?

    return 0 if @purchase.expired? && @purchase.start_date.nil? # sunsetted packages will be status expired but nil start_date

    return (@purchase.expired_on.to_date - @purchase.start_date).to_i if @purchase.expired?

    (Time.zone.today - @purchase.start_date + 1).to_i
  end

  def days_frozen
    @purchase.freezes.map(&:days_frozen).inject(0, :+)
  end

  def active_membership
    days_passed - days_frozen
  end

  def intended_membership
   purchase.product.duration.in_days.ceil + purchase.adjustments.sum(:adjustment)
  end

  def can_transfer?
    return false unless purchase.groupex? && !purchase.dropin? && !purchase.trial? && !purchase.rider?

    return false if purchase.days_to_expiry.days < 3.weeks

    true
  end  

  def transfer_charge
    usage_charge + price_change_charge + Setting.transfer_fixed_charge
  end

  def usage_charge
    return (active_membership.to_f / intended_membership * purchase.charge).floor if purchase.unlimited_package?

    (purchase.bookings.no_amnesty.size.to_f / purchase.max_classes * purchase.charge).floor
  end

  def price_change_charge
    price_change = purchase.product.base_price_at(Time.zone.now).price - purchase.charge
    [0, price_change].max
  end

end
