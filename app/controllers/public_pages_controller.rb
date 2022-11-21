class PublicPagesController < ApplicationController
  def welcome
    if logged_in_as?('junioradmin', 'admin', 'superadmin')
      # not && return won't work because of precedence of operator over method call
      redirect_to admin_clients_path and return
    elsif logged_in_as?('client')
      redirect_to client_client_path(current_account.clients.first) and return
    elsif logged_in_as?('partner')
      redirect_to admin_partner_path(current_account.partners.first) and return
    end
    render template: 'auth/sessions/new'
  end
end
