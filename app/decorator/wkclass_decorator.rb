class WkclassDecorator < BaseDecorator

  def initialize(wkclass)
    # rails c
    # wkd=WkclassDecorator.new(Wkclass.last)
    # do the normal Delegator intializing, then a bit more
    super
    @uncancelled_bookings = wkclass.uncancelled_bookings&.size || 0
  end

  def name_link(page)
    link_maker(instructorised_name, nil, nil, wkclass_path(self), {link_from: 'wkclasses_index', page: page}, {}, ['like_button'])
  end

  def date
    start_time.strftime('%a %d %b %y')
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
    "#{@uncancelled_bookings} #{image_tag('reserve.png', class: "header_icon")}".html_safe
  end

  def spaces_left
    "#{max_capacity - @uncancelled_bookings} #{image_tag('group.png', class: "header_icon")}".html_safe
  end

  def number_on_waiting_list
    "#{self.waitings.size} #{image_tag('waiting.png', class: "header_icon")}".html_safe
  end  

  def sell_online(link)
    link ? link_maker(nil, sell_online_image, nil, product_path(self), {sellonline: !sellonline?}, { method: :patch }, nil) : sell_online_image
  end

  def current(link)
    link ? link_maker(nil, nil, current_image, product_path(self), {current: !current?}, { method: :patch }, nil) : current_image
  end

  def edit(authorised, page)
    if authorised
      link = link_to image_tag('edit.png', class: "table_icon"), edit_wkclass_path(self, page: page)
    else
      link = link_to image_tag('edit.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'
    end
    content_tag(:div, link, class: %w[column nomobile])
  end

  def delete(authorised, deletable, page)
    if authorised && deletable
      tooltip_title = "This class will be deleted. It has no bookings, attendances or cancellations, so it is safe to do so.".gsub(' ',"\u00a0")
      confirm_message = "The class has no bookings, attendances or cancellations so can be deleted. But are you sure?"
      link = link_to image_tag('delete.png', class: "table_icon"), wkclass_path(self, page: page), data: { "turbo-method": :delete, turbo_confirm: confirm_message }
    else
      tooltip_title = "This product has bookings, attendances or cancellations and so can not be deleted".gsub(' ',"\u00a0")
      link = link_to image_tag('delete.png', class: %w[table_icon greyed-out]), '#', class: 'disabled'    
    end
    content_tag(:div, link, class: %w[column nomobile], data:{ toggle:"tooltip", placement: 'top'}, title: tooltip_title )
  end

  private
  
  def sell_online_image
    tag.i class: ["bi", "bi-basket", ("greyed-out" unless sellonline?)]
  end

  def current_image
    image_tag('bookings.png', class: ["table_icon",("greyed-out" unless current?)].compact.join(' '))
  end
end