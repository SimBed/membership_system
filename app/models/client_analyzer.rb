class ClientAnalyzer
  def initialize(client)
    @client = client
    @group_packages = @client.purchases.service_type('group').package
  end
  attr_reader :client, :group_packages

  def group_package_count
    @group_packages.size
  end

  def joined
    @client.created_at
  end

  def first_class
    @group_packages.started.joins(attendances: [:wkclass]).where.not(attendances: { amnesty: true }).minimum(:start_time)
  end

  def life_span
    return 0 if first_class.nil?

    (Time.zone.today.to_date - first_class.to_date + 1).to_i
  end

  def total_active_membership
    total_days = 0
    @group_packages.started.each do |package|
      # next if package.not_started?
      membership = Membership.new(package)
      total_days += membership.active_membership
    end
    total_days.to_i
  end

  def prop_active
    # (total_active_membership.to_f / life_span.to_f * 100).round(1)
    # Style guide prefers .to_f on 1 side only or Float division method Numeric#fdiv
    (total_active_membership.fdiv(life_span) * 100).round(1)
  end

  def total_spend
    @group_packages.map(&:payment).inject(0, :+)
  end
end
