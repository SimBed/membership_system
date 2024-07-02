module PurchasesHelper
  def penalties_header(purchase)
    number_of_penalties = pluralize(purchase.penalties.size, 'Penalty')
    number_of_penalty_days = pluralize(purchase.penalty_days, 'day')
    "#{number_of_penalties} (#{number_of_penalty_days})"
  end

  def penalty_days(penalty)
    "#{pluralize(penalty.amount, 'day')}"
  end
end
