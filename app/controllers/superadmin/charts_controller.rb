class Superadmin::ChartsController < Superadmin::BaseController
  before_action :set_year, only: [:purchase_count_by_wg, :purchase_charge_by_wg, :product_group_count, :product_pt_count]
  before_action :set_last_full_year_period, only: [:purchase_count_by_wg, :purchase_charge_by_wg, :product_group_count, :product_pt_count]
  before_action :set_workout_group_order, only: [:purchase_count_by_wg, :purchase_charge_by_wg]
  before_action :set_product_display_limit, only: [:product_group_count, :product_pt_count]

  def purchase_count_by_week
    chart_data = Chart.set_timezone_and_process { Purchase.all.group_by_week(:dop).count }
    render json: chart_data
  end
  
  def purchase_charge_by_week
    # Purchase.includes(:bookings, :product, :client).sum(:payment) duplicates payments because includes becomes single query joins in this situation    
    # Bullet.enable = false if Rails.env == 'development'    
    # Would like to replace 'Purchase.where(id: @purchases.map(&:id))' with '@purchases' but without this hack @purchase_charge_by_week gives strange results (doubling up on some purchases)...haven't resolved
    # think this issue has gone away now
    chart_data = Chart.set_timezone_and_process { Purchase.all.group_by_week(:dop).sum(:charge) }
    render json: chart_data    
    # Bullet.enable = true if Rails.env == 'development'    
  end

  def purchase_count_by_wg
    # want a consistent colour across the years in the donut for the main workout groups 
    # https://stackoverflow.com/questions/4283295/how-to-sort-an-array-in-ruby-to-a-particular-order
    chart_data = Purchase.count_by_workout_group(@year..@year.end_of_year)
                         .sort_by { |key, value| @workout_group_order.fetch(key, @workout_group_order.length) }
    render json: chart_data
  end

  def purchase_charge_by_wg
    chart_data = Purchase.charge_by_workout_group(@year..@year.end_of_year)
                         .sort_by { |key, value| @workout_group_order.fetch(key, @workout_group_order.length) }
    render json: chart_data
  end

  def product_group_count
    product_order = Chart.product_order('group', @last_year_period, @product_display_limit * 2) # set limit to a number bigger than @product_display_limit as not all years will have the same set of biggest selling products
    chart_data = Product.count_for_service_purchased_during('group', @year..@year.end_of_year, @product_display_limit)
                        .sort_by { |key, value| product_order.fetch(key, product_order.length) }
    render json: chart_data
  end

  def product_pt_count
    product_order = Chart.product_order('pt', @last_year_period, @product_display_limit * 2)    
    chart_data = Product.count_for_service_purchased_during('pt', @year..@year.end_of_year, @product_display_limit)
                        .sort_by { |key, value| product_order.fetch(key, product_order.length) }
    render json: chart_data
  end

  private

  def set_year
    @year = Date.new(params[:year].to_i, 1, 1)    
  end

  def set_last_full_year_period
    end_date = Time.zone.today
    start_date = end_date.last_year.advance(days: 1)
    @last_year_period = start_date..end_date
  end

  def set_workout_group_order
    @workout_group_order = Chart.workout_group_order(@last_year_period)
  end

  def set_product_display_limit
    @product_display_limit = Rails.application.config_for(:constants)['product_piechart_display_limit'] # more than 9 looks messy in pie chart legend
  end

end