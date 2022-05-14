module ApplicationHelper
  # prepare items for date selection (in revenues index, client show)
  def months_logged
    # order_by_date sorts descending
    first_class_date = Wkclass.order_by_date.last.start_time - 1.month
    last_class_date = Wkclass.order_by_date.first.start_time
    # @months = shouldn't be here?
    @months = months_between(first_class_date, last_class_date)
  end

  # used in purchases controller
  def clear_session(*args)
    args.each do |session_key|
      session[session_key] = nil
    end
  end

  private

  def months_between(a, b)
    (a.beginning_of_month.to_date..b.to_date).select { |d| d.day == 1 }.map { |d| d.strftime('%b %Y') }
  end
end
