class Client::ClientsController < ApplicationController
  layout 'client'
  before_action :correct_account, except: [:timetable]
  before_action :set_timetable, only: [:welcome, :space_home]

  def show
    prepare_data_for_view
  end

  def buy

  end

  def shop
    # @products = Product.package.includes(:workout_group).order_by_name_max_classes.reject {|p| p.pt? || p.base_price.nil?}
    @products = Product.online_order_by_wg_classes_days.reject { |p| p.base_price_at(Time.zone.now).nil? }.reject { |p| p.trial? }
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
    @purchases = @client.purchases.not_fully_expired.service_type('group').package.order_by_dop
    # @renewal = @client.renewal
    @renewal = Renewal.new(@client)
    @quotation = Setting.quotation
  end

  def pt
    @unexpired_purchases = @client.purchases.not_fully_expired.service_type('pt').order_by_dop.includes(:attendances)
  end

  def timetable
    # update to base on Setting
    # @timetable = Timetable.first
    # @days = @timetable.table_days.order_by_day
    # @morning_times = @timetable.table_times.during('morning').order_by_time
    # @afternoon_times = @timetable.table_times.during('afternoon').order_by_time
    # @evening_times = @timetable.table_times.during('evening').order_by_time
    # render "public_pages/timetable", layout: "timetable"
    # if Rails.env.test?
    #   @timetable = Timetable.first
    # else
    #   @timetable = Timetable.find(Setting.timetable)
    # end
    @timetable = Timetable.find(Setting.timetable)
    @days = @timetable.table_days.order_by_day
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
end
