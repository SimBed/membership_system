class WorkoutDecorator < BaseDecorator
  include ActionView::RecordIdentifier # for dom_id
  def name_link
    link_maker(name, nil, nil, workout_path(self), nil, { turbo: false }, ['like_button'])
    link = link_to name, workout_path(self), class: ["like_button", ("fw-bolder" if current?)].compact.join(' '), data: { turbo_frame: dom_id(self) }
    tooltip_title = I18n.t('workout_warning').gsub(' ',"\u00a0")
    content_tag :div,
                link,
                class: ["column", "col-2x", ("warning" if has_no_workout_group?)].compact.join(' '),
                data: { toggle: 'tooltip', placement: 'top' },
                title: tooltip_title     
  end
  
  def current
    image = image_tag 'bookings.png', class: ["table_icon",("greyed-out" unless current?)].compact.join(' ')
    link_maker(nil, nil, image, workout_path(self), { current: !current? }, { method: :patch }, nil)
  end

  def edit
    image = image_tag 'edit.png', class: "table_icon"
    link_maker(nil, nil, image, edit_workout_path(self), nil, {}, nil)
  end
end