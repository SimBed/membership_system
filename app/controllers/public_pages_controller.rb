class PublicPagesController < ApplicationController
  def welcome
    if logged_in_as?('junioradmin', 'admin', 'superadmin')
      redirect_to admin_clients_path
    elsif logged_in_as?('client')
      redirect_to client_client_path(current_account.clients.first)
    elsif logged_in_as?('partner')
      redirect_to admin_partner_path(current_account.partners.first)
    end
  end
end
