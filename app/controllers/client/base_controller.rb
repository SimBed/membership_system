class Client::BaseController < ApplicationController
  before_action :correct_account
  before_action :set_chime
  layout 'client'

  def correct_account
    # client booking cancellation route is of the form ':client_id/booking_cancellations/:id' whereas other client routes are of the form '/:id/shop'
    @client = Client.find(params[:client_id] || params[:id])
    redirect_to login_path unless current_account?(@client.account)
  end  

  def set_chime
    # return unless @client
    @chime = @client.account.notifications.unread.present?
  end
end