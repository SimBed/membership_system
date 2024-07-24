module Client::ClientsHelper
  def number(whatsapp, phone)
    return nil if whatsapp.blank? && phone.blank?

    return phone.phony_formatted(format: :international, spaces: '-') if phone.present?

    whatsapp.phony_formatted(format: :international, spaces: '-')
  end

  def booking_day_name(index, day)
    return 'today'.capitalize if index.zero?
    return 'tomorrow'.capitalize if index == 1

    day.strftime('%a').capitalize
  end

  private

end
