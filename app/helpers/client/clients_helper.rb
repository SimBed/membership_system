module Client::ClientsHelper

  def number(whatsapp, phone)
    return nil if whatsapp.blank? && phone.blank?

    return phone.phony_formatted(format: :international, spaces: '-') unless phone.blank?

    whatsapp.phony_formatted(format: :international, spaces: '-')
  end

  def booking_link_and_class_for(wkclass, client)
    attendance = Attendance.applicable_to(wkclass, client)
    if attendance.nil?
      handle_new_booking(wkclass, client)
    else
      handle_update_booking(attendance, wkclass, client)
    end
  end

  # updated - if already booked for eg nutrition on a separate package would not be able to book a group class on same day
  def handle_new_booking(wkclass, client)
    purchase = Purchase.use_for_booking(wkclass, client)
    if purchase.nil? ||
       # wkclass.committed_on_same_day?(client) ||
       purchase.restricted_on?(wkclass) ||
       !wkclass.booking_window.cover?(Time.zone.now)
      { css_class: 'table-secondary', link: '' }
    else
      confirmation = t('client.clients.attendance.create.confirm')
      confirmation = t('client.clients.attendance.create.confirm_unfreeze') if purchase.freezed?(wkclass.start_time)
      { css_class: 'table-secondary',
        link: link_to(
          image_tag('add.png', class: 'table_icon'),
          admin_attendances_path('attendance[wkclass_id]': wkclass.id,
                                 'attendance[purchase_id]': purchase.id),
          method: :post,
          data: { confirm: confirmation },
          class: 'icon-container'
        ) }

    end
  end

  def handle_update_booking(attendance, wkclass, client)
    case attendance.status
    when 'booked'
      { css_class: 'table-success',
        link: link_to_update(attendance, amendment: 'cancel') }
    when 'cancelled early'
      # if wkclass.committed_on_same_day?(client)
      if attendance.purchase.restricted_on?(wkclass)
        { css_class: 'table-secondary', link: '' }
    else
      { css_class: 'table-secondary',
        link: link_to_update(attendance, amendment: 'rebook') }
    end
    when 'cancelled late', 'no show'
      { css_class: 'table-danger', link: '' }
    else # 'attended'
      { css_class: 'table-secondary', link: '' }
    end
  end

  def link_to_update(attendance, amendment:)
    if amendment == 'cancel'
      png = 'delete.png'
      confirmation = t('client.clients.attendance.update.from_booked.confirm')
    else
      png = 'add.png'
      confirmation = t('client.clients.attendance.update.from_cancelled_early.confirm')
      confirmation = t('client.clients.attendance.update.from_cancelled_early.confirm_unfreeze') if attendance.purchase.freezed?(attendance.wkclass.start_time)
    end
    link_to(
      image_tag(png, class: 'table_icon'),
      admin_attendance_path(attendance),
      method: :patch,
      data: { confirm: confirmation },
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

  def shop_discount_statement(ongoing, trial)
    return "Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" if ongoing.nil?
    return "Renew your Package before expiry with a #{format_rate(:renewal_pre_package_expiry)}% online discount!" if ongoing && !trial
    return "Buy your first Package before your trial expires with a #{format_rate(:renewal_pre_trial_expiry)}% online discount!" if ongoing && trial

    "Buy your first Package with a #{format_rate(:renewal_post_trial_expiry)}% online discount!" # if !ongoing && trial
  end

  def visit_shop_statement(rider)
    return "Visit the #{link_to 'Shop', client_shop_path(@client), class: 'shop_button'} now".html_safe if !rider

    "Visit the #{link_to 'Shop', client_shop_path(@client), class: 'shop_button'} for more group classes".html_safe
  end

  def renewal_saving(product, renewal)
    renewal.base_price(product).price - renewal.price(product)
  end

  private

  def format_rate(renewal_type)
    number_with_precision(Discount.rate(Time.zone.now.to_date)[renewal_type][:percent], strip_insignificant_zeros: true)
  end
end
