module ApplicationHelper

  def flash_message(type, text)
    flash[type] ||= []
    flash[type] << (text.is_a?(Array) ? text : [text])
  end

  def render_flash
    rendered = []
    flash.each do |message_type, message_array|
      rendered << render(:partial => 'partials/flash', :locals => {:message_type => message_type, :message_array => message_array}) unless message_array.blank?
    end
    raw(rendered.join('<br/>'))
  end

  # prepare items for date selection
  def months_logged
    # order_by_date sorts descending
    first_class_date = Wkclass.order_by_date.last.start_time - 1.month
    last_class_date = Wkclass.order_by_date.first.start_time
    # @months = shouldn't be here?
    @months = months_between(first_class_date, last_class_date)
  end

  def nillify_when_blank(params, *params_items)
    params_items.each { |item| params[item] = nil if params[item] == '' }
  end

  def month_period(date)
    date = Date.parse(date) unless date.is_a? Date
    beginning_of_period = date.beginning_of_month
    end_of_period = date.end_of_month.end_of_day
    (beginning_of_period..end_of_period)
  end

  private

  def months_between(start_date, end_date)
    (start_date.beginning_of_month.to_date..end_date.to_date).select { |d| d.day == 1 }.map { |d| d.strftime('%b %Y') }
  end

end
