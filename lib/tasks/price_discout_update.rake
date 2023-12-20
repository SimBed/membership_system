desc 'update prices for change in discount rate'
task price_update_discount: :environment do
  Price.where(renewal_pretrial_expiry: true, current: true).each do |old_price|
    new_price = old_price.dup
    old_price.update(current: false)
    new_price.discount = Setting.pre_expiry_trial_renewal.to_f
    new_price.price = new_price.discounted_price
    new_price.date_from = Time.zone.today
    new_price.name = 'Early Trial Renewal'
    new_price.save
  end

  Price.where(renewal_posttrial_expiry: true, current: true).each do |old_price|
    new_price = old_price.dup
    old_price.update(current: false)
    new_price.discount = Setting.post_expiry_trial_renewal.to_f
    new_price.price = new_price.discounted_price
    new_price.date_from = Time.zone.today
    new_price.name = 'Late Trial Renewal'
    new_price.save
  end
end
