module Client::ClientsHelper
  def number(whatsapp, phone)
    return nil if whatsapp.blank? && phone.blank?

    return phone.phony_formatted(format: :international, spaces: '-') if phone.present?

    whatsapp.phony_formatted(format: :international, spaces: '-')
  end

  def renewal_statement(ongoing, trial, valid)
    # ongoing trial
    return "Buy your first Package before your trial expires with a #{format_rate(:renewal_pre_trial_expiry)}% online discount!" if ongoing && trial

    # ongoing package
    return "Renew your Package before expiry with a #{format_rate(:renewal_pre_package_expiry)}% online discount!" if ongoing && !trial && valid

    return "Buy your next Package before expiry with a #{format_rate(:renewal_pre_package_expiry)}% online discount!" if ongoing && !trial && !valid

    # expired trial
    return "Your Trial has expired. Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" if !ongoing && trial

    # expired package
    'Your Group Package has expired. Renew your Package now!'
  end

  def shop_discount_statement(ongoing, trial, oneoff)
    return 'Special Discount Applies' if oneoff
    return "Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" if ongoing.nil?
    return "Renew your Package before expiry with a #{format_rate(:renewal_pre_package_expiry)}% online discount!" if ongoing && !trial
    return "Buy your first Package before your trial expires with a #{format_rate(:renewal_pre_trial_expiry)}% online discount!" if ongoing && trial

    "Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" if !ongoing && trial
  end

  def visit_shop_statement(rider)
    return "Visit the #{link_to 'Shop', client_shop_path(@client), class: 'like_button text-uppercase', data: {turbo: false}} now".html_safe unless rider

    "Visit the #{link_to 'Shop', client_shop_path(@client), class: 'like_button text-uppercase', data: {turbo: false}} for more group classes".html_safe
  end

  def booking_image_prev(workout_name)
    path = "group/#{workout_name}.jpg"
    default = '/assets/group/defaultbooking.jpg'
    return "/assets/group/#{workout_name}.jpg" if asset_exist?(path)

    default
  end

  def booking_image(workout_name)
    path = "group/#{workout_name}.jpg"
    default = 'group/defaultbooking.jpg'
    return path if asset_exist?(path)

    default
  end

  def booking_day_name(index, day)
    return 'today'.capitalize if index.zero?
    return 'tomorrow'.capitalize if index == 1

    day.strftime('%a').capitalize
  end

  # not used
  def day_index(date)
    (date - Time.zone.now.to_date).to_i
  end

  private

  def format_rate(renewal_type)
    number_with_precision(Discount.rate(Time.zone.now.to_date)[renewal_type][:percent], strip_insignificant_zeros: true)
  end

  # https://stackoverflow.com/questions/6782978/rails-3-1-determine-if-asset-exists
  def asset_exist?(path)
    if Rails.configuration.assets.compile
      Rails.application.precompiled_assets.include? path
    else
      Rails.application.assets_manifest.assets[path].present?
    end
  end
end
