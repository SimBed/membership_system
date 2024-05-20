class NavbarPresenter
  # viet 6 Nov 2022 https://stackoverflow.com/questions/489641/using-helpers-in-model-how-do-i-include-helper-dependencies
  delegate :link_to, to: 'ActionController::Base.helpers'

  def dropdown_item(name, url, authorised)
    return nil unless authorised

    link_to(name, url, class: 'dropdown-item')
  end
end