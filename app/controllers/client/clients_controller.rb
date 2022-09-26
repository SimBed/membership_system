class Client::ClientsController < ApplicationController
  before_action :correct_account

  def show
    prepare_data_for_view
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
