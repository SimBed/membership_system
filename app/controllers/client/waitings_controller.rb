class Client::WaitingsController < ApplicationController
  before_action :correct_account
  before_action :set_booking_day
  before_action :set_wkclass, only: :create
  before_action :at_capacity, only: :create
  before_action :valid_package, only: :create

  def create
    Waiting.create(wkclass_id: params[:wkclass_id], purchase_id: params[:purchase_id])
    redirect_to client_book_path(current_account.client, booking_section: params[:booking_section])
    flash_message :success, t('.success', wkclass_name: @wkclass.name)
    # flash[:success] = "You have been added to the waiting list for #{wkclass.name}. You will be sent a message if a spot opens up."
  end

  def destroy
    waiting = Waiting.find(params[:id])
    wkclass_name = waiting.wkclass.name
    waiting.destroy
    redirect_to client_book_path(current_account.client, booking_section: params[:booking_section])
    flash_message :success, t('.success', wkclass_name:)
  end

  private

  def correct_account
    @purchase = Purchase.where(id: params[:purchase_id]).first || Waiting.find(params[:id]).purchase
    @client = @purchase.client

    return if current_account?(@client.account)

    redirect_to login_path
    flash_message :warning, t('.warning')
  end

  # so day on slider shown doesn't revert to default on response, make dry repeated in bookings_controller
  def set_booking_day
    default_booking_day = 0
    session[:booking_day] = params[:booking_day] || session[:booking_day] || default_booking_day
  end

  def set_wkclass
    @wkclass = Wkclass.find(params[:wkclass_id])
  end

  def at_capacity
    return if @wkclass.at_capacity?

    flash_message :warning, t('.warning')
    redirect_to login_path
  end

  def valid_package
    return if Purchase.use_for_booking(@wkclass, @client, restricted: false)&.id == params[:purchase_id].to_i

    # occasionally a client may cancel early and subsequently wish to join the waiting list (use_for_booking method rejects (via already_used_for? method purchases with bookings associated to the class))
    return if @client.associated_with?(@wkclass)

    flash_message :warning, t('.warning')
    redirect_to login_path
  end
end
