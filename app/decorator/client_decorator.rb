class ClientDecorator < BaseDecorator

  def name_link(link)
    link ? link_maker(name, nil, nil, client_path(self), {link_from: 'clients_index'}, {}, ['like_button']) : name
  end

  def number
    return nil if whatsapp.blank? && phone.blank?

    return phone.phony_formatted(format: :international, spaces: '-') if phone.present?

    whatsapp.phony_formatted(format: :international, spaces: '-')
  end
  
  def submitted_declaration(in_table: true)
    tooltip_title = if declaration
      "This client has completed a health declaration.".gsub(' ',"\u00a0")
    else
      "This client has not completed a health declaration, so may not yet book classes.".gsub(' ',"\u00a0")
    end    
    image = image_tag('health.png', class: ["table_icon",("dull" unless declaration)].compact.join(' '))
    return content_tag(:span, image, data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title) unless in_table

    content_tag(:div, image, class: %w[column nomobile], data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title)
  end

  def instagram_ok
    tooltip_title = if instawaiver?
                      "This client has approved hash-tagging on Instagram and can be tagged.".gsub(' ',"\u00a0")
                    else
                      "This client has not approved hash-tagging on Instagram and should not be tagged".gsub(' ',"\u00a0")
                    end
    link = link_to image_tag('insta.png', class: ["table_icon",("greyed-out" unless instawaiver?)].compact.join(' ')),
                   client_path(self, instawaiver: !instawaiver?),
                   data: { "turbo-method": :patch }
    content_tag('turbo-frame', link, id: "insta-#{id}", data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title)                 
  end

  def in_whatsapp_group
    tooltip_title = if whatsapp_group?
                      "This client has been added to the community whatsapp group.".gsub(' ',"\u00a0")
                    else
                      "This client has not been added to the community whatsapp group.".gsub(' ',"\u00a0")
                    end
    link = link_to image_tag('whatsapp.png', class: ["table_icon",("greyed-out" unless whatsapp_group?)].compact.join(' ')),
                   client_path(self, whatsapp_group: !whatsapp_group?),
                   data: { "turbo-method": :patch }
    return content_tag('turbo-frame', link, id: "whatsapp-group-#{id}", data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title)
  end

  def edit(link_from: nil)
    link_to image_tag('edit.png', class: "table_icon"), edit_client_path(self, link_from:)
  end

  def delete(authorised, deletable)
    if authorised && deletable
      tooltip_title = "This client will be deleted. It has no account nor purchases so it is safe to do so.".gsub(' ',"\u00a0")
      confirm_message = "The Client has no account nor purchases so can be deleted. But are you sure?"
      link = link_to image_tag('delete.png', class: "table_icon"), client_path(self), data: { "turbo-method": :delete, turbo_confirm: confirm_message }
    else
      tooltip_title = "This client has an account or purchases and so can not be deleted".gsub(' ',"\u00a0")
      link = link_to image_tag('delete.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'    
    end
    content_tag(:div, link, class: %w[column nomobile], data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title)
  end

  def status_image
    image_file = status_icon[0]
    tooltip_title = status_icon[1]
    image_tag(image_file, data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title) unless image_file.nil?
  end

  def delete_account(authorised, client)
    return nil unless authorised && client.account 
    # weird nuance of tooltips with spaces - https://stackoverflow.com/questions/45621314/html-title-tooltip-gets-cut-off-after-spaces
    tooltip_title = "The account will be deleted. No data will be deleted, however #{client.first_name} will no longer be able to log in.".gsub(' ',"\u00a0")
    confirm_message = "The account will be deleted. No data will be deleted, however #{client.first_name} will no longer be able to log in. Are you sure?"
    link = link_to image_tag('delete-account.png', class: "table_icon"), account_path(client.account), data: { turbo_method: :delete, turbo_confirm: confirm_message }
    content_tag(:div, link, class: %w[d-inline], data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title)
  end

  def forgot_password(authorised, client)
    return nil unless authorised && client.account
    tooltip_title = "The client's password will be reset and they will be sent a whatsapp containing their new password.".gsub(' ',"\u00a0")
    confirm_message = "This client's password will be reset. Are you sure?"
    link = link_to image_tag('forgot-password.png', class: "table_icon"), account_path(client.account, requested_by: 'admin'), data: { turbo_method: :patch, turbo_confirm: confirm_message }
    content_tag(:div, link, class: %w[d-inline], data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title)
  end

  def add_account(authorised, client)
    return nil if client.account || !authorised 
    tooltip_title = "An account will be created for #{client.first_name} and a whatsapp message sent.".gsub(' ',"\u00a0")
    confirm_message = "An account will be created for #{client.first_name} and a whatsapp message sent. Are you sure?"
    link = link_to image_tag('add.png', class: "table_icon"), accounts_path(email: client.email, id: client.id, role_name: 'client'), data: { turbo_method: :post, turbo_confirm: confirm_message }
    content_tag(:div, link, class: %w[d-inline], data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title)
  end

  private

  def status_icon
    return ['hot.png', 'Hot lead, high level of interest.'] if hotlead?
    return ['cold.png', "Client has not attended a class for more than #{Setting.cold} months."]  if cold?
    return ['enquiry.png', 'Enquiry, not yet made a purchase.'] if enquiry?
    
    [nil, nil]
  end

end