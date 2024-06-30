class BasePresenter
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper
  # viet 6 Nov 2022 https://stackoverflow.com/questions/489641/using-helpers-in-model-how-do-i-include-helper-dependencies
  delegate :button_tag, :content_tag, :link_to,  to: 'ActionController::Base.helpers'   
end