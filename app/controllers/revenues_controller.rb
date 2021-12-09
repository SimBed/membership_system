#require 'byebug'
class RevenuesController < ApplicationController
  def index
    session[:revenue_date] = params[:revenue_date] || session[:revenue_date] || Date.today.beginning_of_month.strftime('%b %Y')
    # prepare attendances by date and workout_group


    @attendances_hash = {}
    # put dates in specified string format fro sql queries
    start_date = Date.parse(session[:revenue_date]).strftime('%Y-%m-%d')
    end_date = Date.parse(session[:revenue_date]).end_of_month.strftime('%Y-%m-%d')

    @wg_revenue_hash = {}

    WorkoutGroup.all.each do |wg|
      attendances = Attendance.in_grouping(wg.name, start_date, end_date)
      base_revenue = attendances.map { |a| a.revenue }.inject(0, :+)
      expiry_revenue =  wg.expiry_revenue(session[:revenue_date])
      @wg_revenue_hash[wg.name.to_sym] = {
        number: attendances.size,
        base_revenue: base_revenue,
        expiry_revenue: expiry_revenue,
        total_revenue: base_revenue + expiry_revenue
      }
    end

  @workout_group_names = WorkoutGroup.all.pluck(:name)

    # prepare items for the revenue date select
    first_class_date = Wkclass.order_by_date.first.start_time - 1.month
    last_class_date = Wkclass.order_by_date.last.start_time
    # months_between method defined in revenues helper
    @months = months_between(first_class_date, last_class_date)
  end


end
