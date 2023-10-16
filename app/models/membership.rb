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
end
