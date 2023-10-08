class ClientAnalyzer
  def initialize(client)
    @client = client
    @group_packages = @client.purchases.service_type('group').package.started
  end
  attr_reader :client

  def group_package_count
    @group_packages.size
  end

  def joined 
    @client.created_at
  end

  def first_class
    @client.attendances.includes(:wkclass).map(&:start_time).min
  end

  def life_span
    (Time.zone.today.to_date - joined.to_date + 1).to_i
  end
  
  def active_membership
    total_days = 0 
    @group_packages.each do |package|
      return if package.start_date_calc.nil?
      package_days = 0
      if package.expired?
        package_days =  package.expiry_date - package.start_date_calc
      else
        package_days = Time.zone.now.to_date - package.start_date_calc
      end
      freeze_days = 0 
      package.freezes.each do |freeze|
        if Time.zone.now > freeze.end_date
          days = freeze.end_date - freeze.start_date + 1
        else
          days = Time.zone.now.to_date - freeze.start_date + 1
        end
        freeze_days += days
      end
      package_active_days = package_days - freeze_days
      total_days = total_days + package_active_days
    end
    total_days.to_i
  end

  def prop_active
    (active_membership.to_f / life_span.to_f * 100).round(1)
  end

  def total_spend
    @group_packages.map(&:payment).inject(0, :+)
  end
end
