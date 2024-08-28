class Superadmin::ChartsController < Superadmin::BaseController
  before_action :set_year, only: [:purchase_count_by_wg, :purchase_charge_by_wg, :product_count]
  before_action :set_sort_order, only: [:purchase_count_by_wg, :purchase_charge_by_wg]

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
    # sort_order = %w[Group Space\ PT Apoorv\ PT Gigi\ PT]
    # lookup = sort_order.each_with_index.to_h
    chart_data = Purchase.count_by_workout_group(@year..@year.end_of_year)
                         .sort_by { |key, value| @sort_order.fetch(key, @sort_order_length) }
    render json: chart_data
  end

  def purchase_charge_by_wg
    chart_data = Purchase.charge_by_workout_group(@year..@year.end_of_year)
                         .sort_by { |key, value| @sort_order.fetch(key, @sort_order_length) }
    render json: chart_data
  end

  def product_count
    chart_data = Product.joins(:purchases)
                        .merge(Purchase.during(@year..@year.end_of_year))
                        .group('products.id')
                        .count
                        .sort_by { |_key, value| -value }
                        .first(9)
                        .to_h
                        .transform_keys{|key| Product.find(key).name(color_show: false)}
    render json: chart_data
  end

  private

  def set_year
    @year = Date.new(params[:year].to_i, 1, 1)    
  end

  def set_sort_order
    @sort_order, @sort_order_length = Chart.purchase_wg_sort_order[0], Chart.purchase_wg_sort_order[1]  
  end

end