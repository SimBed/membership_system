module Client::ClientsHelper
  def booking_link_and_class_for(wkclass, client)
    attendance = Attendance.applicable_to(wkclass, client)
    if attendance.nil?
      if wkclass.booking_on_same_day?(client) || ['provisionally expired', 'provisionally expired (and frozen)'].include?(Purchase.available_for_booking(wkclass, client).status) 
        ['unbooked', '']
      else
        ['unbooked', link_to(image_tag('add.png', class: "grid_table_icon"), admin_attendances_path('attendance[wkclass_id]': wkclass.id, 'attendance[purchase_id]': Purchase.available_for_booking(wkclass, client).id), method: :post, data: { confirm: 'You will be booked for this class. Are you sure?' }, class: "icon-container")]
      end
    else
      case attendance.status
      when 'attended'
        ['bg-secondary', '']
      when 'booked'
        # ['booked', link_to(image_tag('delete.png', class: "grid_table_icon"), admin_attendance_path(attendance, attendance: { intent: 'modify' }), method: :patch, data: { confirm: 'You will be cancelled for this class. Are you sure?' }, class: "icon-container")]
        ['bg-success', link_to(image_tag('delete.png', class: "grid_table_icon"), admin_attendance_path(attendance), method: :patch, data: { confirm: 'You will be cancelled for this class. Deductions may apply to late cancellations and no-shows. Are you sure?' }, class: "icon-container")]
      when 'cancelled early'
        if wkclass.booking_on_same_day?(client)
          ['unbooked', '']
        else
          ['unbooked', link_to(image_tag('add.png', class: "grid_table_icon"), admin_attendance_path(attendance), method: :patch, data: { confirm: 'You will be rebooked for this class. Are you sure?' }, class: "icon-container")]
        end
      when 'cancelled late'
        ['bg-danger', '']
      when 'no show'
        ['bg-danger', '']
      else #safety net
          ['bg-secondary', '']
      end
    end
  end
end
