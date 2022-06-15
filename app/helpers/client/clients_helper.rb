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
      { css_class: 'table-secondary',
        link: link_to(
          image_tag('add.png', class: 'grid_table_icon'),
          admin_attendances_path('attendance[wkclass_id]': wkclass.id,
                                 'attendance[purchase_id]': purchase.id),
          method: :post,
          data: { confirm: t('client.clients.attendance.create.confirm') },
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
    end
    link_to(
      image_tag(png, class: 'grid_table_icon'),
      admin_attendance_path(attendance),
      method: :patch,
      data: { confirm: confirmation },
      class: 'icon-container'
    )
  end
end
