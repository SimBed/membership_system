module PublicPagesHelper
  def timetable_day_name(day, todays_day, tomorrows_day, length)
    return 'today' if day == todays_day

    return 'tomorrow' if day == tomorrows_day

    length == :short_name ? day.slice(0,2) : day
  end
end
