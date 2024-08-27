class Superadmin::ChartsController < Superadmin::BaseController
  # HACK: for timezone issue with groupdata https://github.com/ankane/groupdate/issues/66  
  before_action :set_utc_timezone
  after_action :set_local_timezone

  def purchase_count_by_week
    render json: Purchase.all.group_by_week(:dop).count
  end
  
  def purchase_charge_by_week
    # Purchase.includes(:bookings, :product, :client).sum(:payment) duplicates payments because includes becomes single query joins in this situation    
    # Bullet.enable = false if Rails.env == 'development'    
    # Would like to replace 'Purchase.where(id: @purchases.map(&:id))' with '@purchases' but without this hack @purchase_charge_by_week gives strange results (doubling up on some purchases)...haven't resolved
    # think this issue has gone away now   
    render json: Purchase.all.group_by_week(:dop).sum(:charge)
    # Bullet.enable = true if Rails.env == 'development'    
  end

  def purchase_count_by_wg
    year = Date.new(params[:year].to_i, 1, 1)
    # i want a consistent colour across the years in the donut for the main workout groups 
    # https://stackoverflow.com/questions/4283295/how-to-sort-an-array-in-ruby-to-a-particular-order
    sort_order = %w[Group Space\ PT Apoorv\ PT Gigi\ PT]
    lookup = sort_order.each_with_index.to_h
    # sort_order.each_with_index do |item, index|
    #   lookup[item] = index
    # end
    render json: Purchase.count_by_workout_group(year..year.end_of_year).sort_by { |key, value| lookup.fetch(key, sort_order.length + 1) }
  end

  def purchase_charge_by_wg
    year = Date.new(params[:year].to_i, 1, 1)    
    sort_order = %w[Group Space\ PT Apoorv\ PT Gigi\ PT]
    lookup = sort_order.each_with_index.to_h
    render json: Purchase.charge_by_workout_group(year..year.end_of_year).sort_by { |key, value| lookup.fetch(key, sort_order.length + 1) }
  end

  private

  def set_utc_timezone
    Purchase.default_timezone = :utc
  end

  def set_local_timezone
    Purchase.default_timezone = :local
  end

end