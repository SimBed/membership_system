class Client::DataPagesController < Client::BaseController
  skip_before_action :correct_account, only: [:timetable]
  skip_before_action :set_chime, only: [:notifications]
  after_action :make_unread, only: :notifications
  
  def notifications
    @notifications = @client.account.notifications.order_by_date
    @chime = false
  end

  def achievements
    achievement_data
    if @achievements.present?
      # HACK: for timezone issue with groupdata https://github.com/ankane/groupdate/issues/66
      Achievement.default_timezone = :utc
      # HACK: hash returned has a key:value pair at each date, but the line_chart doesnt join dots when there are nil values in between, so remove nil values with #compact
      @achievements_grouped = @challenge&.achievements&.where(client_id: @client.id)&.group_by_day(:date)&.average(:score)&.compact
      Achievement.default_timezone = :local
    end
    @client_results = @challenge.results if @achievements.present? || @main_challenge_selected
  end 
   
  def profile
    prepare_data_for_view
    clear_session(:challenge_id)
    session[:challenge_id] ||= params[:challenge_id] || @client.challenges.order_by_name.distinct&.first&.id
    @challenge = Challenge.find_by(id: session[:challenge_id])
    @challenges_entered = @client.challenges.order_by_name.distinct.map { |c| [c.name, c.id] }
    # HACK: for timezone issue with groupdata https://github.com/ankane/groupdate/issues/66
    @achievements = @challenge&.achievements&.where(client_id: @client.id)
    return if @achievements.blank?

    Achievement.default_timezone = :utc
    # HACK: hash returned has a key:value pair at each date, but the line_chart doesnt join dots when there are nil values in between, so remove nil values with #compact
    @achievements_grouped = @achievements&.group_by_day(:date)&.average(:score)&.compact
    Achievement.default_timezone = :local
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

  def pt
    @unexpired_purchases = @client.purchases.not_fully_expired.service_type('pt').order_by_dop.includes(:bookings)
  end

  def timetable
    @entries_hash = Timetable.display_entries(show_publicly_invisible: true)
    render 'timetable', layout: 'client_black'
  end  

  private

  def make_unread
    @client.account.notifications.unread.update_all(read_at: Time.zone.now)
  end

  def prepare_data_for_view
    @account = @client.account
    @client_hash = {
      attendances: @client.bookings.attended.size,
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
    @achievements = @challenge&.achievements&.where(client_id: @client.id)&.order_by_date
    @main_challenge_selected = true if main_challenge_ids.include? session[:challenge_id].to_i
  end  
end
