class Client::BaseController < ApplicationController
  before_action :correct_account
  layout 'client'

  def correct_account
    # client booking cancellation route is of the form ':client_id/booking_cancellations/:id' whereas other client routes are of the form '/:id/shop' 
    @client = Client.find(params[:client_id] || params[:id])
    redirect_to login_path unless current_account?(@client.account)
  end  
end