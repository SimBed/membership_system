# very weird syntax to pass argument (did not use in the end)
# task :expiry_message_send, [:days] => :environment do |t, args|
# at command line: rake "expiry_message_send[2]"
# https://stackoverflow.com/questions/1357639/how-to-pass-arguments-into-a-rake-task-with-environment-in-rails
desc 'send expiry messages'
task expiry_message_send: :environment do
  # https://stackoverflow.com/questions/76224452/rake-task-with-both-active-record-and-view-helpers
  include ActionView::Helpers::NumberHelper
  #  Purchase.package_started_not_fully_expired.reject(&:pt?).reject(&:trial?).each do |p|
  Purchase.package_started_not_fully_expired.renewable.reject(&:trial?).each do |p|
    # code if passing arguments
    # if p.days_to_expiry == args.days.to_i && p.client.purchases.package.not_started.reject(&:pt?).empty?
    # don't spam clients who have already renewed
    # if p.days_to_expiry == Setting.package_expiry_message_days.to_i && p.client.purchases.package.not_started.reject(&:pt?).empty?
    if p.days_to_expiry == Setting.package_expiry_message_days.to_i && p.client.purchases.package.not_started.renewable.empty?
      hash = { receiver: p.client,
               message_type: 'package_expiry',
               variable_contents: { first_name: p.client.first_name,
                                    day: p.expiry_date.strftime('%A'),
                                    discount: number_with_precision(Discount.rate(Time.zone.now.to_date)[:renewal_pre_package_expiry][:percent], strip_insignificant_zeros: true) } }
      Whatsapp.new(hash).manage_messaging
    end
  end

  # reject pt not needed but precautionary
  # Purchase.package_started_not_fully_expired.trial.reject(&:pt?).each do |p|
  Purchase.package_started_not_fully_expired.renewable.trial.each do |p|
    # if p.days_to_expiry == Setting.trial_expiry_message_days.to_i && p.client.purchases.package.not_started.reject(&:pt?).empty?
    if p.days_to_expiry == Setting.trial_expiry_message_days.to_i && p.client.purchases.package.not_started.renewable.empty?
      hash = { receiver: p.client,
               message_type: 'trial_expiry',
               variable_contents: { first_name: p.client.first_name,
                                    day: p.expiry_date.strftime('%A'),
                                    discount: number_with_precision(Discount.rate(Time.zone.now.to_date)[:renewal_pre_trial_expiry][:percent], strip_insignificant_zeros: true) } }
      Whatsapp.new(hash).manage_messaging
    end
  end
end
