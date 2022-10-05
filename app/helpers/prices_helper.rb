module PricesHelper
  def purpose(price)
    %i[base renewal_pre_expiry renewal_pretrial_expiry renewal_posttrial_expiry].each do |purpose_type|
      return purpose_type.to_s if price.send(purpose_type)
    end
    # nil is necessary beacuae otherwise the return value when there is no purpose_type would bethe last statement evaluated,
    # which in that in that context would be [:base, :renewal_pre_expiry, :renewal_pretrial_expiry, :renewal_posttrial_expiry]
      nil
  end

end
