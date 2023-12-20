module ClientsHelper
  def status_icon(client)
    return 'hot.png' if client.hotlead?
    return 'cold.png' if client.cold?

    'enquiry.png' if client.enquiry?
  end
end
