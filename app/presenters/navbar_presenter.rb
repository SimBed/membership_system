class NavbarPresenter < BasePresenter

  def dropdown_item(name, url, authorised)
    return nil unless authorised

    link_to(name, url, class: 'dropdown-item')
  end
end