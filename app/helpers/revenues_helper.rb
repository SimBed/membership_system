module RevenuesHelper
  def months_between(start_date, end_date)
    (start_date.beginning_of_month.to_date..end_date.to_date).select { |d| d.day == 1 }.map { |d| d.strftime('%b %Y') }
  end
end
