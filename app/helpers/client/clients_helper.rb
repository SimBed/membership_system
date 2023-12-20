module Client::ClientsHelper
  def number(whatsapp, phone)
    return nil if whatsapp.blank? && phone.blank?

    return phone.phony_formatted(format: :international, spaces: '-') unless phone.blank?

    whatsapp.phony_formatted(format: :international, spaces: '-')
  end

  def booking_link_and_class_for(wkclass, client, day, booking_section)
    attendance = Attendance.applicable_to(wkclass, client)
    if attendance.nil?
      handle_new_booking(wkclass, client, day, booking_section)
    else
      handle_update_booking(attendance, wkclass, client, day, booking_section)
    end
  end

  def handle_new_booking(wkclass, client, day, booking_section)
    purchase = Purchase.use_for_booking(wkclass, client)
    if purchase.nil? ||
       purchase.restricted_on?(wkclass) ||
       !wkclass.booking_window.cover?(Time.zone.now)
      { css_class: 'table-secondary', link: '' }
    elsif wkclass.at_capacity?
      confirmation = t('client.clients.attendance.create.full')
      # remarkably difficult to have a tooltip with spaces in it
      # https://stackoverflow.com/questions/45621314/html-title-tooltip-gets-cut-off-after-spaces
      title = "class\u00a0is\u00a0currently\u00a0full"
      { css_class: 'table-secondary',
        data_attributes: 'data-toggle=tooltip',
        tooltip_title: "title=#{title}",
        link: (link_to '#', class: 'icon-container disable-link' do tag.i class: ['bi bi-battery-full'] end) }
    else
      confirmation = t('client.clients.attendance.create.confirm')
      confirmation = t('client.clients.attendance.create.confirm_unfreeze') if purchase.freezed?(wkclass.start_time)
      { css_class: '',
        link: link_to(
          image_tag('add.png', class: "table_icon mx-auto #{'filter-white' unless wkclass.workout.limited?}"),
          admin_attendances_path('attendance[wkclass_id]': wkclass.id,
                                 'attendance[purchase_id]': purchase.id,
                                 'booking_day': day,
                                 'booking_section': booking_section),
          data: { turbo_method: :post, turbo_confirm: confirmation },
          class: 'icon-container'
        ) }

    end
  end

  def handle_update_booking(attendance, wkclass, client, day, booking_section)
    case attendance.status
    when 'booked'
      { css_class: 'text-success',
        link: link_to_update(attendance, day, amendment: 'cancel', booking_section:) }
    when 'cancelled early'
      if attendance.purchase.restricted_on?(wkclass)
        { css_class: '', link: '' }
      else
        { css_class: '',
          link: link_to_update(attendance, day, amendment: 'rebook', booking_section:) }
      end
    when 'cancelled late', 'no show'
      { css_class: 'text-danger', link: '' }
    else # 'attended'
      { css_class: '', link: '' }
    end
  end

  def link_to_update(attendance, day, amendment:, booking_section:)
    if amendment == 'cancel'
      image = 'delete.png'
      image_class = 'table_icon mx-auto filter-red'
      confirmation = t('client.clients.attendance.update.from_booked.confirm')
    else
      image = 'add.png'
      image_class = "table_icon mx-auto #{'filter-white' unless attendance.wkclass.workout.limited?}"
      confirmation = t('client.clients.attendance.update.from_cancelled_early.confirm')
      confirmation = t('client.clients.attendance.update.from_cancelled_early.confirm_unfreeze') if attendance.purchase.freezed?(attendance.wkclass.start_time)
    end
    link_to(
      image_tag(image, class: image_class),
      admin_attendance_path(attendance, 'booking_day': day, 'booking_section': booking_section),
      data: { turbo_method: :patch, turbo_confirm: confirmation },
      class: 'icon-container'
    )
  end

  def renewal_statement(ongoing, trial, valid, client)
    if valid
      return "Buy your first Package before your trial expires with a #{format_rate(:renewal_pre_trial_expiry)}% online discount!" if ongoing && trial
      return "Renew your Package before expiry with a #{format_rate(:renewal_pre_package_expiry)}% online discount!" if ongoing && !trial
      return "Your Trial has expired. Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" if !ongoing && trial

      'Your Group Package has expired. Renew your Package now!'
    else
      return "Buy your first Package before your trial expires with a #{format_rate(:renewal_pre_trial_expiry)}% online discount!" if ongoing && trial
      return "Buy your next Package before expiry with a #{format_rate(:renewal_pre_package_expiry)}% online discount!" if ongoing && !trial
      return "Your Trial has expired. Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" if !ongoing && trial

      'Your Group Package has expired. Renew your Package now!'
    end
  end

  def shop_discount_statement(ongoing, trial, oneoff)
    return 'Special Discount Applies' if oneoff
    return "Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" if ongoing.nil?
    return "Renew your Package before expiry with a #{format_rate(:renewal_pre_package_expiry)}% online discount!" if ongoing && !trial
    return "Buy your first Package before your trial expires with a #{format_rate(:renewal_pre_trial_expiry)}% online discount!" if ongoing && trial

    "Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" if !ongoing && trial
  end

  def visit_shop_statement(rider)
    return "Visit the #{link_to 'Shop', client_shop_path(@client), class: 'like_button text-uppercase'} now".html_safe unless rider

    "Visit the #{link_to 'Shop', client_shop_path(@client), class: 'like_button text-uppercase'} for more group classes".html_safe
  end

  # def renewal_saving(product, renewal)
  #   renewal.base_price(product).price - renewal.price(product)
  # end

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
    return 'today'.capitalize if index == 0
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
