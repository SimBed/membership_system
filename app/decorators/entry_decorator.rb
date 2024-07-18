class EntryDecorator < BaseDecorator
  def time_period
    time = table_time.start
    time_end = time.advance(minutes: duration)
    "#{time.strftime('%l.%M')} - #{time_end.strftime('%l.%M')}"
  end

  def goal_formatted
    (goal.presence || '-')
  end

  def level_foramtted
    (level.presence || '-')
  end
end
