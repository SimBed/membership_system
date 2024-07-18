class BaseDecorator < SimpleDelegator
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper
  # viet 6 Nov 2022 https://stackoverflow.com/questions/489641/using-helpers-in-model-how-do-i-include-helper-dependencies
  delegate :image_tag, :tag, :content_tag, :link_to, to: 'ActionController::Base.helpers'

  # link_maker('Group UC:1M', nil, nil, product_path(self), nil, {turbo: false}, ['like_button'])
  # <a data-turbo="false" class="like_button" href="/products/4?">Group UC:1M</a>
  def link_maker(text_params, icon_params, image_params, route, route_params, turbo_params, classes_array)
    name = if image_params
             image_params
           elsif icon_params
             icon_params
           else
             text_params
           end
    url = "#{route}?#{route_params&.to_query}"
    data = { 'turbo-method': turbo_params[:method], turbo_confirm: turbo_params[:confirmation], turbo: turbo_params[:turbo] }
    css_classes = classes_array&.compact&.join(' ')
    link_to(name, url, data:, class: css_classes)
  end

  def rupees(amount)
    number_to_currency(amount, precision: 0, unit: 'Rs. ')
  end
end
