module PricesHelper
  # def purpose(price)
  #   %i[base renewal_pre_expiry renewal_pretrial_expiry renewal_posttrial_expiry].each do |purpose_type|
  #     return purpose_type.to_s if price.send(purpose_type)
  #   end
  #   # nil is necessary because otherwise the return value when there is no purpose_type would be the last statement evaluated,
  #   # which in that context would be [:base, :renewal_pre_expiry, :renewal_pretrial_expiry, :renewal_posttrial_expiry]
  #     nil
  # end

  # def full_name(price)
    # discount = price.discount.zero? ? '' : " #{number_with_precision(price.discount, precision: 2, strip_insignificant_zeros: true)}%"
    # "#{price.name}#{discount}"
  # end

  # def discount_format(discount)
  #   "#{number_with_precision(discount, precision: 2, strip_insignificant_zeros: true)}%"
  # end

end
