module PublicPagesHelper
  def timetable_day_name(index, day, tomorrow, length)
    return 'today' if index == 0

    return 'tomorrow' if index == 1 && day == tomorrow

    length == :short ? day.slice(0,2) : day
  end
end
