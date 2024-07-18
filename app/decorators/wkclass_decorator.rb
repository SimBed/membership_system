class WkclassDecorator < BaseDecorator
  def initialize(wkclass)
    # rails c
    # wkd=WkclassDecorator.new(Wkclass.last)
    # do the normal Delegator intializing, then a bit more
    super
    @uncancelled_bookings = wkclass.uncancelled_bookings.size # &.size || 0
  end

  def pt_client_name
    pt? && bookings.present? ? bookings.first.client.name : nil
  end

  def pt_status
    pt? && bookings.present? ? bookings.first.status : nil
  end

  def rate_formatted
    number_with_delimiter(rate)
  end

  def name_link(page)
    link_maker(instructorised_name, nil, nil, wkclass_path(self), { link_from: 'wkclasses_index', page: }, {}, ['like_button'])
  end

  def name_link_in_purchase_show_tables(purchase_link_from_id)
    link_maker(name, nil, nil, wkclass_path(self), { link_from: 'purchase_show', purchase_link_from_id: }, { turbo: false }, ['like_button'])
  end

  def name_link_in_wg_instructor_expense_table
    link_maker(summary, nil, nil, wkclass_path(self), { link_from: 'workout_group_show' }, { turbo: false }, ['like_button'])
  end

  def date
    start_time.strftime('%a %d %b %y')
  end

  def date_no_year
    start_time.strftime('%a %b %-d')
  end

  def time
    start_time.strftime('%H:%M')
  end

  def summary
    "#{name}, #{date}, #{time}"
  end

  def instructorised_name
    return name if !workout.instructor_initials? || instructor.nil?

    "#{name} (#{instructor.initials})"
  end

  def spaces_taken
    "#{@uncancelled_bookings} #{image_tag('reserve.png', class: 'header_icon')}".html_safe
  end

  def spaces_left
    "#{max_capacity - @uncancelled_bookings} #{image_tag('group.png', class: 'header_icon')}".html_safe
  end

  def number_on_waiting_list
    "#{waitings.size} #{image_tag('waiting.png', class: 'header_icon')}".html_safe
  end

  def sell_online(link)
    link ? link_maker(nil, sell_online_image, nil, product_path(self), { sellonline: !sellonline? }, { method: :patch }, nil) : sell_online_image
  end

  def current(link)
    link ? link_maker(nil, nil, current_image, product_path(self), { current: !current? }, { method: :patch }, nil) : current_image
  end

  def edit(authorised, page, purchase_link_from_id, link_from, put_in_div: true)
    link = if authorised
             link_to image_tag('edit.png', class: 'table_icon'), edit_wkclass_path(self, page:, purchase_link_from_id:, link_from:)
           else
             link_to image_tag('edit.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'
           end
    return link unless put_in_div

    content_tag(:div, link, class: %w[column nomobile])
  end

  def delete(authorised, deletable, page, purchase_link_from_id, link_from)
    if authorised && deletable
      tooltip_title = confirm_message = I18n.t('.wkclass_delete')
      link = link_to image_tag('delete.png', class: 'table_icon'), wkclass_path(self, page:, purchase_link_from_id:, link_from:),
                     data: { 'turbo-method': :delete, turbo_confirm: confirm_message }
    else
      tooltip_title = I18n.t('wkclass_delete_no')
      link = link_to image_tag('delete.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'
    end
    content_tag(:div, link, class: %w[column nomobile], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  def cancel_link(page, purchase_link_from_id, link_from)
    if link_from == 'purchase_show'
      link_to image_tag('delete.png', class: 'table_icon'), purchase_path(purchase_link_from_id), data: { turbo: false }
    else
      link_to image_tag('delete.png', class: 'table_icon'), wkclasses_path(page:, purchase_link_from_id:, link_from:)
    end
  end

  private

  def sell_online_image
    tag.i class: ['bi', 'bi-basket', ('greyed-out' unless sellonline?)]
  end

  def current_image
    image_tag('bookings.png', class: ['table_icon', ('greyed-out' unless current?)].compact.join(' '))
  end
end
