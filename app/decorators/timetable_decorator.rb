class TimetableDecorator < BaseDecorator
  def title_link
    link_to title, timetable_path(self), class: 'like_button'
  end

  def date_fromm
    date_from&.strftime('%d %b %y')
  end

  def date_untill
    date_until&.strftime('%d %b %y')
  end

  def edit
    link_to image_tag('edit.png', class: "table_icon"), edit_timetable_path(self), data: { turbo: false }
  end  

  def delete
    link_to image_tag('delete.png', class: "table_icon"), timetable_path(self), data: { turbo_method: :delete, turbo_confirm: I18n.t('.timetable_delete') }
  end

  def copy
    link_to image_tag('clipboard.png', class: "table_icon"), timetable_deep_copy_path(self), data: { turbo_method: :post, turbo_confirm: I18n.t('.timetable_copy') }
  end

  def display(use_for_display)
    return image_tag 'display.png', class: 'table_icon', data: { toggle: 'tooltip', placement: 'top' }, title: I18n.t('.timetable_display') if use_for_display

    image_tag 'display.png', class: 'table_icon dull'
  end

  def wkclass_maker(use_for_wkclass)
    return image_tag 'build.png', class: 'table_icon', data: { toggle: 'tooltip', placement: 'top' }, title: I18n.t('.timetable_wkclassmaker') if use_for_wkclass
    
    image_tag 'build.png', class: 'table_icon dull'
  end
end
