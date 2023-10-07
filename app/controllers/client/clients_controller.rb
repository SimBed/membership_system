class Client::ClientsController < ApplicationController
  layout 'client'
  before_action :correct_account, except: [:timetable]

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
    end
    @client_results = @challenge.results if @achievements.present? || @main_challenge_selected
  end

  def shop
    @products = Product.online_order_by_wg_classes_days.reject { |p| p.base_price_at(Time.zone.now).nil? }.reject(&:trial?)
    # @products = @products.reject {|p| p.trial?} if logged_in? && current_account.client.has_purchased?
    # https://blog.kiprosh.com/preloading-associations-while-using-find_by_sql/
    # https://apidock.com/rails/ActiveRecord/Associations/Preloader/preload
    # ActiveRecord::Associations::Preloader.new.preload(@products, :workout_group)
    # Rails 7 update
    # https://stackoverflow.com/questions/74430650/rails-7-activerecordassociationspreloader-new-preload    
    ActiveRecord::Associations::Preloader.new(
      records: @products,
      associations: :workout_group
    ).call    
    @renewal = Renewal.new(@client)
    # to update razorpay button from default 'Pay Now'
    @trial_price = Product.trial.space_group.first.base_price_at(Time.zone.now).price
    @last_product_fixed = @renewal.product.fixed_package?
  end

  def book
    session[:booking_day] = params[:booking_day] || session[:booking_day] || '0'
    # @wkclasses_visible = Wkclass.show_in_bookings_for(@client).order_by_reverse_date
    # @wkclasses_window_closed = @wkclasses_visible.select { |w| w.booking_window.end < Time.zone.now }
    # @wkclasses_not_yet_open = @wkclasses_visible.select { |w| w.booking_window.begin > Time.zone.now }
    # @wkclasses_in_booking_window = @wkclasses_visible - @wkclasses_window_closed - @wkclasses_not_yet_open
    @wkclasses_show = Wkclass.limited.show_in_bookings_for(@client).order_by_reverse_date
    @open_gym_wkclasses = Wkclass.unlimited.show_in_bookings_for(@client).order_by_reverse_date
    @days = (Date.today..Date.today.advance(days: Setting.visibility_window_days_ahead)).to_a
    # Should be done in model
    @wkclasses_show_by_day = []
    @opengym_wkclasses_show_by_day = []
    @days.each do |day|
      @wkclasses_show_by_day.push(@wkclasses_show.on_date(day))
      @opengym_wkclasses_show_by_day.push(@open_gym_wkclasses.on_date(day))
    end
    @other_services = OtherService.all
    # include attendances and wkclass so can find last booked session in PT package without additional query
    @purchases = @client.purchases.not_fully_expired.service_type('group').package.order_by_dop.includes(attendances: [:wkclass])
    @renewal = Renewal.new(@client)
    respond_to do |format|
      format.html
      if params[:limited] == 'true' # ie not open gym
        format.turbo_stream
      else
        format.turbo_stream {  render :book_opengym }
      end
    end
  end

  def pt
    @unexpired_purchases = @client.purchases.not_fully_expired.service_type('pt').order_by_dop.includes(:attendances)
  end

  def timetable
    @timetable = Timetable.find(Rails.application.config_for(:constants)['timetable_id'])
    @days = @timetable.table_days.order_by_day
    @entries_hash = {}
    @days.each do |day|
      @entries_hash[day.name] = Entry.where(table_day_id: day.id).includes(:table_time, :workout).order_by_start
    end
    # used to establish whether 2nd day in the timetable slider is tomorrow or not
    @todays_day = Date.today.strftime("%A")    
    @tomorrows_day = Date.tomorrow.strftime("%A")
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
      last_counted_class: @client.last_counted_class,
      date_created: @client.created_at,
      date_last_purchase_expiry: @client.last_purchase&.expiry_date
    }
  end

  def achievement_data
    main_challenge_ids = @client.challenges.where.not(challenge_id: nil).pluck(:challenge_id).uniq
    main_challenges = Challenge.where(id: main_challenge_ids)
    @challenges = main_challenges + @client.challenges.order_by_name.distinct.to_a
    clear_session(:challenge_id)
    session[:challenge_id] ||= params[:challenge_id] || @challenges&.last&.id
    @challenge = Challenge.find_by(id: session[:challenge_id])
    @challenges_entered = @challenges.map { |c| [c.name, c.id] }
    @achievements = @challenge&.achievements&.where(client_id: params[:id])&.order_by_date
    @main_challenge_selected = true if main_challenge_ids.include? session[:challenge_id].to_i
  end
end