class Client::ClientsController < ApplicationController
  before_action :correct_account

  def show
    clear_session(:purchaseid)
    session[:purchaseid] = params[:purchaseid] || session[:purchaseid] || 'Ongoing'
      if session[:purchaseid] == 'All'
      @purchases = @client.purchases.order_by_dop
      else
      # easier than using with_statuses[all except expired] scope
      @purchases = @client.purchases.order_by_dop.where.not(status: 'expired')
    end if
    @client_hash = {
      attendances: @client.attendances.size,
      last_class: @client.last_class,
      date_created: @client.created_at,
      date_last_purchase_expiry: @client.last_purchase&.expiry_date
    }

  @products_purchased = ['Ongoing', 'All']
  end

  def book
    @wkclass_booked = Wkclass.booked_by(@client)
    @wkclasses_bookable = Wkclass.bookable_by(@client)
    @wkclasses_potentially_bookable =
      Wkclass.potentially_bookable_by(@client) - @wkclasses_bookable - @wkclass_booked
  end

  private

  def correct_account
    @client = Client.find(params[:id])
    redirect_to login_path unless current_account?(@client.account)
  end

end
