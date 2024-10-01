module Superadmin::BulkFreezesHelper
  def processed_message
    "'#{@note}' freeze scheduled for #{duration} #{period}"
  end

  def duration
    days = (@start_date..@end_date).count
    ActionController::Base.helpers.pluralize(days, 'day')
  end

  def period
    "#{Date.parse(@start_date).strftime('%-d %B %Y')} to #{Date.parse(@end_date).strftime('%-d %B %Y')}"
  end
end
