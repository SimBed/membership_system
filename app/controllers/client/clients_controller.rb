class Client::ClientsController < ApplicationController
  def show
    @client = current_account.clients.first
  end
end
