class Client::ClientsController < ApplicationController
  layout 'client'
  before_action :correct_account, except: [:timetable]
  before_action :set_timetable, only: [:welcome, :space_home]  

  def show
    prepare_data_for_view
  end

  def buy
    
  end

  def book
    @wkclasses_visible = Wkclass.show_in_bookings_for(@client).order_by_reverse_date
    @wkclasses_window_closed = @wkclasses_visible.select { |w| w.booking_window.end < Time.zone.now }
    @wkclasses_not_yet_open = @wkclasses_visible.select { |w| w.booking_window.begin > Time.zone.now }
    @wkclasses_in_booking_window = @wkclasses_visible - @wkclasses_window_closed - @wkclasses_not_yet_open
    # @wkclasses_in_booking_window = @wkclasses_visible.select { |w| w.booking_window.cover?(Time.zone.now) }
    @purchases = @client.purchases.package.not_fully_expired
    @renewal = @client.renewal
    @quotation = Setting.quotation
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
    render "timetable", layout: 'client_black'    
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
    @client_hash = {
      attendances: @client.attendances.attended.size,
      last_class: @client.last_class,
      date_created: @client.created_at,
      date_last_purchase_expiry: @client.last_purchase&.expiry_date
    }
  end
end
