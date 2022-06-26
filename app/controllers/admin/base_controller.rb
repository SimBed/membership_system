class Admin::BaseController < ApplicationController
  # layout 'admin'
  before_action :admin_account

  def update_purchase_status(purchases)
    # this has to be done as separate requests as each calc is dependent on the previously updated attribute
    # this could be avoided and done as one update request with some reformatting of the calc methods (to include an optional argument)
    purchases.each do |p|
      p.update(start_date: p.start_date_calc)
      p.update(expiry_date: p.expiry_date_calc)
      p.update(status: p.status_calc)
    end

    # p.update(
    #   { status: p.status_calc,
    #     expiry_date: p.expiry_date_calc,
    #     start_date: p.start_date_calc })
  end

  def white_list_whatsapp_receivers
    whatsapp_receivers = %w[Amala Aadrak Fluke Cleo James]
    whatsapp_receivers.include?(@purchase.client.first_name)
  end  
end
