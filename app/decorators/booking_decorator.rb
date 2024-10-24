class BookingDecorator < BaseDecorator
  def close_to_expiry
    return 'bg-info' if status == 'booked' && purchase.close_to_expiry? && !purchase.dropin?

    nil
  end

  def payment_outstanding
    return 'bg-danger' if status == 'booked' && client.payment_outstanding?

    nil
  end

  def missing_health_declaration
    return 'bg-danger-subtle' if %w[booked attended].include?(status) && client.declaration.nil?

    nil
  end

  # def client_name_link(authorised)
  #   return client.name unless authorised

  #   link_maker(client.name, nil, nil, client_path(client), nil, { turbo: false }, ['like_button'])
  # end

  def client_name_link(authorised)
    name = if authorised
            link_maker(client.name, nil, nil, client_path(client), nil, { turbo: false }, ['like_button'])
           else
            client.name
           end
    css_classes = ["column col-2x-sm", ("student" if client.student?)].compact.join(' ')     
    content_tag(:div, name, class: css_classes)  
  end


  def product_name_link(authorised)
    return product.name unless authorised

    link_maker(product.name, nil, nil, purchase_path(purchase), nil, { turbo: false }, ['like_button'])
  end

  def delete(authorised, page, purchase_link_from_id, link_from)
    if authorised
      tooltip_title = confirm_message = I18n.t('.booking_delete')
      link = link_to image_tag('delete.png', class: 'table_icon'), booking_path(self, page:, purchase_link_from_id:, link_from:),
                     data: { 'turbo-method': :delete, turbo_confirm: confirm_message }
    else
      link = link_to image_tag('delete.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'
    end
    content_tag(:div, link, class: %w[column], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end
end
