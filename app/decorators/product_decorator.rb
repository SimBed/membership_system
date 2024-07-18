class ProductDecorator < BaseDecorator
  def name_link(link)
    link ? link_maker(name(rider_show: true), nil, nil, product_path(self), nil, { turbo: false }, ['like_button']) : name(rider_show: true)
  end

  def sell_online(link)
    link ? link_maker(nil, sell_online_image, nil, product_path(self), { sellonline: !sellonline? }, { method: :patch }, nil) : sell_online_image
  end

  def current(link)
    link ? link_maker(nil, nil, current_image, product_path(self), { current: !current? }, { method: :patch }, nil) : current_image
  end

  def edit(authorised, editable)
    if authorised && editable
      tooltip_title = I18n.t('.product_edit')
      link = link_to image_tag('edit.png', class: 'table_icon'), edit_product_path(self)
    else
      tooltip_title = I18n.t('.product_edit_no')
      link = link_to image_tag('edit.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'
    end
    content_tag(:div, link, class: %w[column nomobile], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  def delete(authorised, deletable)
    if authorised && deletable
      tooltip_title = confirm_message = I18n.t('.product_delete')
      link = link_to image_tag('delete.png', class: 'table_icon'), product_path(self), data: { 'turbo-method': :delete, turbo_confirm: confirm_message }
    else
      tooltip_title = I18n.t('.product_delete_no')
      link = link_to image_tag('delete.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'
    end
    content_tag(:div, link, class: %w[column nomobile], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  private

  def sell_online_image
    tag.i class: ['bi', 'bi-basket', ('greyed-out' unless sellonline?)]
  end

  def current_image
    image_tag('bookings.png', class: ['table_icon', ('greyed-out' unless current?)].compact.join(' '))
  end
end
