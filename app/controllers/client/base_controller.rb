class Client::BaseController < ApplicationController
  before_action :correct_account
  layout 'client'

  def correct_account
    @client = Client.find(params[:id])
    redirect_to login_path unless current_account?(@client.account)
  end  
end
