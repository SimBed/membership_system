class Client::ClientsController < ApplicationController
  before_action :correct_account

  def show
    @client = current_account.clients.first
  end

  private

  def correct_account
    @client = Client.find(params[:id])
    redirect_to login_path unless current_account?(@client.account)
  end

end
