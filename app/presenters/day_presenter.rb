class DayPresenter
  delegate :button_tag, to: 'ActionController::Base.helpers'

  def initialize(attributes = {})
    @day = attributes[:day]
    @index = attributes[:index]
    @todays_day = Time.zone.today.strftime('%A')
    @tomorrows_day = Date.tomorrow.strftime('%A')
  end

  def button
    button_tag timetable_day_name(use_short_name: true).capitalize,
               type: 'button',
               class: ["slider_btn", ("live" if @index == 0)].compact.join(' '),
               data: {day: @index}
  end

  def timetable_day_name(use_short_name: true)
    return 'today' if @day == @todays_day

    return 'tomorrow' if @day == @tomorrows_day

    use_short_name ? @day.slice(0, 2) : @day
  end

  def next_occurring
    Date.yesterday.next_occurring(@day.downcase.to_sym).strftime("%b %e")
  end
end