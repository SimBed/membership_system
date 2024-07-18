class ClientDecorator < BaseDecorator
  def name_link(link)
    link ? link_maker(name, nil, nil, client_path(self), { link_from: 'clients_index' }, {}, ['like_button']) : name
  end

  def number
    return nil if whatsapp.blank? && phone.blank?

    return phone.phony_formatted(format: :international, spaces: '-') if phone.present?

    whatsapp.phony_formatted(format: :international, spaces: '-')
  end

  def submitted_declaration(in_table: true)
    tooltip_title = if declaration
                      I18n.t('.submitted_declaration')
                    else
                      I18n.t('.submitted_declaration_no')
                    end
    image = image_tag('health.png', class: ['table_icon', ('dull' unless declaration)].compact.join(' '))
    return content_tag(:span, image, data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title) unless in_table

    content_tag(:div, image, class: %w[column nomobile], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  def instagram_ok
    tooltip_title = if instawaiver?
                      I18n.t('.instagram_ok')
                    else
                      I18n.t('.instagram_ok_no')
                    end
    link = link_to image_tag('insta.png', class: ['table_icon', ('greyed-out' unless instawaiver?)].compact.join(' ')),
                   client_path(self, instawaiver: !instawaiver?),
                   data: { 'turbo-method': :patch }
    content_tag('turbo-frame', link, id: "insta-#{id}", data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  def in_whatsapp_group
    tooltip_title = if whatsapp_group?
                      I18n.t('.in_whatsapp_group')
                    else
                      I18n.t('.in_whatsapp_group_no')
                    end
    link = link_to image_tag('whatsapp.png', class: ['table_icon', ('greyed-out' unless whatsapp_group?)].compact.join(' ')),
                   client_path(self, whatsapp_group: !whatsapp_group?),
                   data: { 'turbo-method': :patch }
    content_tag('turbo-frame', link, id: "whatsapp-group-#{id}", data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  def edit(link_from: nil)
    link_to image_tag('edit.png', class: 'table_icon'), edit_client_path(self, link_from:)
  end

  def delete(authorised, client)
    if authorised && client.deletable?
      tooltip_title = confirm_message = I18n.t('.delete_client', first_name: client.first_name)
      link = link_to image_tag('delete.png', class: 'table_icon'), client_path(self), data: { 'turbo-method': :delete, turbo_confirm: confirm_message }
    else
      tooltip_title = I18n.t('.delete_client_no', first_name: client.first_name)
      link = link_to image_tag('delete.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'
    end
    content_tag(:div, link, class: %w[column nomobile], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  def status_image
    image_file = status_icon[0]
    tooltip_title = status_icon[1]
    image_tag(image_file, data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title) unless image_file.nil?
  end

  def delete_account(authorised, client)
    return nil unless authorised && client.account

    tooltip_title = confirm_message = I18n.t('.delete_account', first_name: client.first_name)
    link = link_to image_tag('delete-account.png', class: 'table_icon'), account_path(client.account), data: { turbo_method: :delete, turbo_confirm: confirm_message }
    content_tag(:div, link, class: %w[d-inline], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  def forgot_password(authorised, client)
    return nil unless authorised && client.account

    tooltip_title = confirm_message = I18n.t('.forgot_password', first_name: client.first_name)
    link = link_to image_tag('forgot-password.png', class: 'table_icon'), account_path(client.account, requested_by: 'admin'),
                   data: { turbo_method: :patch, turbo_confirm: confirm_message }
    content_tag(:div, link, class: %w[d-inline], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  def add_account(authorised, client)
    return nil if client.account || !authorised

    # weird nuance of tooltips with spaces - https://stackoverflow.com/questions/45621314/html-title-tooltip-gets-cut-off-after-spaces
    # the nuance seemes to have gone away, but kept 1 example of workaround code for potsterity
    tooltip_title = "An account will be created for #{client.first_name} and a whatsapp message sent.".gsub(' ', "\u00a0")
    confirm_message = I18n.t('.add_account', first_name: client.first_name)
    link = link_to image_tag('add.png', class: 'table_icon'), accounts_path(email: client.email, id: client.id, role_name: 'client'),
                   data: { turbo_method: :post, turbo_confirm: confirm_message }
    content_tag(:div, link, class: %w[d-inline], data: { toggle: 'tooltip', placement: 'top' }, title: tooltip_title)
  end

  private

  def status_icon
    return ['hot.png', I18n.t('.hot')] if hotlead?
    return ['cold.png', I18n.t('.cold', month: Setting.cold)] if cold?
    return ['enquiry.png', I18n.t('.enquiry')] if enquiry?

    [nil, nil]
  end
end
