#require 'byebug'
class RevenuesController < ApplicationController
  def index
    session[:revenue_period] = params[:revenue_period] || session[:revenue_period] || Date.today.beginning_of_month.strftime('%b %Y')
    # prepare attendances by date and workout_group
    # put dates in specified string format for sql queries
    start_date = Date.parse(session[:revenue_period]).strftime('%Y-%m-%d')
    end_date = Date.parse(session[:revenue_period]).end_of_month.strftime('%Y-%m-%d')
    @wg_revenue_hash = {}
    WorkoutGroup.all.each do |wg|
      attendances = Attendance.by_workout_group(wg.name, start_date, end_date)
      base_revenue = attendances.map { |a| a.revenue }.inject(0, :+)
      expiry_revenue =  wg.expiry_revenue(session[:revenue_period])
      @wg_revenue_hash[wg.name.to_sym] = {
        number: attendances.size,
        base_revenue: base_revenue,
        expiry_revenue: expiry_revenue,
        total_revenue: base_revenue + expiry_revenue
      }
    end

    @workout_group_names = WorkoutGroup.all.pluck(:name)

    # prepare items for the revenue date select
    # months_logged method defined in application helper
    @months = months_logged
  end
end
