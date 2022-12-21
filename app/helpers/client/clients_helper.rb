module Client::ClientsHelper
  def booking_link_and_class_for(wkclass, client)
    attendance = Attendance.applicable_to(wkclass, client)
    if attendance.nil?
      handle_new_booking(wkclass, client)
    else
      handle_update_booking(attendance, wkclass, client)
    end
  end

  def handle_new_booking(wkclass, client)
    purchase = Purchase.use_for_booking(wkclass, client)
    if purchase.nil? ||
       wkclass.committed_on_same_day?(client) ||
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
      if wkclass.committed_on_same_day?(client)
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
      if attendance.purchase.freezed?(attendance.wkclass.start_time)
        confirmation = t('client.clients.attendance.update.from_cancelled_early.confirm_unfreeze')
      end
    end
    link_to(
      image_tag(png, class: 'table_icon'),
      admin_attendance_path(attendance),
      method: :patch,
      data: { confirm: confirmation },
      class: 'icon-container'
    )
  end

  def renewal_statement(ongoing, trial)
    return 'Buy your first Package before your trial expires with a 20% discount!' if ongoing && trial
    return 'Renew your Package before expiry with a 10% discount!' if ongoing
    return "Buy your first Package with a 15% discount!" if trial

    "Renew your Package now!"
  end

end
