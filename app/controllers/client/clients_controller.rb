class Client::ClientsController < ApplicationController
  before_action :correct_account

  def show
    prepare_data_for_view
  end

  def book
    @wkclasses = Wkclass.show_in_bookings_for(@client).order_by_reverse_date
    # @wkclass_booked = Wkclass.booked_by(@client)
    # @wkclasses_bookable = Wkclass.bookable_by(@client)
    # @wkclasses_potentially_bookable =
    #   Wkclass.potentially_bookable_by(@client) - @wkclasses_bookable - @wkclass_booked
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
    # prepare_data_for_view
    @products_purchased = %w[Ongoing All]
  end

  private

  def correct_account
    @client = Client.find(params[:id])
    redirect_to login_path unless current_account?(@client.account)
  end

  def prepare_data_for_view
    @client_hash = {
      attendances: @client.attendances.size,
      last_class: @client.last_class,
      date_created: @client.created_at,
      date_last_purchase_expiry: @client.last_purchase&.expiry_date
    }
  end
end
