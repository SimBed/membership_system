class Client::ClientsController < ApplicationController
  layout 'client'
  before_action :correct_account, except: [:timetable]
  before_action :set_timetable, only: [:welcome, :space_home]

  def show
    prepare_data_for_view
    clear_session(:challenge_id)
    session[:challenge_id] ||= params[:challenge_id] || @client.challenges.order_by_name.distinct&.first&.id
    @challenge = Challenge.find_by(id: session[:challenge_id])
    @challenges_entered = @client.challenges.order_by_name.distinct.map { |c| [c.name, c.id] }
    # HACK: for timezone issue with groupdata https://github.com/ankane/groupdate/issues/66
    @achievements = @challenge&.achievements&.where(client_id: params[:id])
    if @achievements.present?
      Achievement.default_timezone = :utc
      # HACK: hash returned has a key:value pair at each date, but the line_chart doesnt join dots when there are nil values in between, so remove nil values with #compact
      @achievements_grouped = @achievements&.group_by_day(:date)&.average(:score).compact
      Achievement.default_timezone = :local
    end
  end

  def challenge
    clear_session(:challenge_id)
    session[:challenge_id] ||= params[:challenge_id]
    @challenge = Challenge.find_by(id: session[:challenge_id])
    @challenges_entered = @client.challenges.order_by_name.distinct.map { |c| [c.name, c.id] }
    @clients = @challenge&.positions
  end

  def achievement
    achievement_data
  end
  
  def achievements
    achievement_data
      if @achievements.present?    
      # HACK: for timezone issue with groupdata https://github.com/ankane/groupdate/issues/66
      Achievement.default_timezone = :utc
      # HACK: hash returned has a key:value pair at each date, but the line_chart doesnt join dots when there are nil values in between, so remove nil values with #compact
      @achievements_grouped = @challenge&.achievements&.where(client_id: params[:id]).group_by_day(:date).average(:score).compact
      Achievement.default_timezone = :local
      @clients = @challenge&.positions
    end          
  end

  def buy

  end

  def shop
    # @products = Product.package.includes(:workout_group).order_by_name_max_classes.reject {|p| p.pt? || p.base_price.nil?}
    @products = Product.online_order_by_wg_classes_days.reject { |p| p.base_price_at(Time.zone.now).nil? }.reject(&:trial?)
    # @products = @products.reject {|p| p.trial?} if logged_in? && current_account.client.has_purchased?
    # https://blog.kiprosh.com/preloading-associations-while-using-find_by_sql/
    # https://apidock.com/rails/ActiveRecord/Associations/Preloader/preload
    ActiveRecord::Associations::Preloader.new.preload(@products, :workout_group)
    # :offer_online_discount? seems to be obsolete now
    # @renewal = @client.renewal #|| { :offer_online_discount? => true, renewal_offer: "renewal_pre_expiry" } # renewal is nil if no purchases yet made
    @renewal = Renewal.new(@client)
    # render template: 'public_pages/shop' #, layout: 'white_canvas'
  end

  def book
    @wkclasses_visible = Wkclass.show_in_bookings_for(@client).order_by_reverse_date
    @wkclasses_window_closed = @wkclasses_visible.select { |w| w.booking_window.end < Time.zone.now }
    @wkclasses_not_yet_open = @wkclasses_visible.select { |w| w.booking_window.begin > Time.zone.now }
    @wkclasses_in_booking_window = @wkclasses_visible - @wkclasses_window_closed - @wkclasses_not_yet_open
    # @wkclasses_in_booking_window = @wkclasses_visible.select { |w| w.booking_window.cover?(Time.zone.now) }
    # incluide attendances and wkclass so can find last booked session in PT package without additional query
    @purchases = @client.purchases.not_fully_expired.service_type('group').package.order_by_dop.includes(attendances: [:wkclass])
    # @renewal = @client.renewal
    @renewal = Renewal.new(@client)
    @quotation = Setting.quotation
  end

  def pt
    @unexpired_purchases = @client.purchases.not_fully_expired.service_type('pt').order_by_dop.includes(:attendances)
  end

  def timetable
    @timetable = Timetable.find(Setting.timetable)
    @days = @timetable.table_days.order_by_day
    @entries_hash = {}
    @days.each do |day|
      @entries_hash[day] = Entry.where(table_day_id: day.id).includes(:table_time, :workout).order_by_start
    end 
    render 'timetable', layout: 'client_black'
  end

  def history
    clear_session(:purchaseid)
    session[:purchaseid] ||= params[:purchaseid] || 'Ongoing'
    @purchases = if session[:purchaseid] == 'All'
                   @client.purchases.order_by_dop
                 else
                   # easier than using statuses[all except expired] scope
                   @client.purchases.order_by_dop.where.not(status: 'expired')
                 end
    @products_purchased = %w[Ongoing All]
  end

  private

  def correct_account
    @client = Client.find(params[:id])
    redirect_to login_path unless current_account?(@client.account)
  end

  def prepare_data_for_view
    @account = @client.account
    @client_hash = {
      attendances: @client.attendances.attended.size,
      last_class: @client.last_class,
      date_created: @client.created_at,
      date_last_purchase_expiry: @client.last_purchase&.expiry_date
    }
  end

  def achievement_data
    @challenges = @client.challenges.order_by_name.distinct    
    clear_session(:challenge_id)
    session[:challenge_id] ||= params[:challenge_id] || @challenges&.first&.id
    @challenge = Challenge.find_by(id: session[:challenge_id])
    @challenges_entered = @challenges.map { |c| [c.name, c.id] }
    @achievements = @challenge&.achievements&.where(client_id: params[:id])&.order_by_date    
  end
end
