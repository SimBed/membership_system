class BookingPresenter < BasePresenter
  def initialize(wkclass, client, day, booking_section)
    @wkclass = wkclass
    @client = client
    @day = day
    @booking_section = booking_section
    @booking = Booking.applicable_to(@wkclass, @client)
    @new_booking = @booking.nil?
    @wkclass_at_capacity = @wkclass.at_capacity?
    @on_waiting_list = client.on_waiting_list_for?(wkclass)
    # if not at capacity then the next column will be occupied with a booking link
    @waiting_list_remove_link_under_status = true if @on_waiting_list && !@wkclass_at_capacity
    @purchase = Purchase.use_for_booking(@wkclass, @client, restricted: false) || @booking&.purchase
    @time = Time.zone.now
  end
  attr_reader :waiting_list_remove_link_under_status

  def booking_image
    workout_name = @wkclass.name.delete(' ').downcase
    path = "group/#{workout_name}.jpg"
    default = 'group/defaultbooking.jpg'
    return path if asset_exist?(path)

    default
  end

  def booking_link
    return link_for_new_booking if @new_booking

    link_for_update_booking
  end

  # this doesn't appear in the usual link column of the booking page, but in the status column when a spot opens up and the client has the option to book or to remove from waiting list
  def waiting_list_remove_link
    waiting = @client.waiting_list_for(@wkclass)
    image_params = { src: 'delete.png',
                     css_class: 'table_icon mx-auto' }
    route = 'client_waiting_path'
    route_params = { id: waiting.id,
                     booking_day: @day,
                     booking_section: @booking_section }
    turbo_params = { method: :delete,
                     confirmation: "You'll be removed from the waiting list" }

    link_maker(image_params, route, route_params, turbo_params)
  end

  # for status
  def css_class
    if @new_booking
      if @purchase.nil? || @wkclass.at_capacity?
        'table-secondary'
      else
        ''
      end
    else
      case @booking.status
      when 'booked'
        'text-success'
      when 'cancelled late', 'no show'
        'text-danger'
      else # attended or cancelled early
        ''
      end
    end
  end

  def data_attributes
    return 'data-toggle=tooltip' if @wkclass_at_capacity || @client.on_waiting_list_for?(@wkclass)

    nil
  end

  def tooltip_title
    # remarkably difficult to have a tooltip with spaces in it
    # https://stackoverflow.com/questions/45621314/html-title-tooltip-gets-cut-off-after-spaces
    title_class_full = "Class\u00a0is\u00a0currently\u00a0full.\u00a0Add\u00a0to\u00a0waiting\u00a0list."
    title_remove_from_waiting_list = "remove\u00a0from\u00a0waiting\u00a0list"
    return "title=#{title_class_full}" if @wkclass_at_capacity && @booking.nil? && !@client.on_waiting_list_for?(@wkclass)

    return "title=#{title_remove_from_waiting_list}" if @wkclass_at_capacity && @client.on_waiting_list_for?(@wkclass)

    nil
  end

  def status
    return 'on waiting list' if @client.on_waiting_list_for?(@wkclass)

    return Booking.applicable_to(@wkclass, @client).status if @client.associated_with?(@wkclass)

    return 'class full' if @wkclass_at_capacity

    ''
  end

  def get_params(booking_situation)
    case booking_situation
    when 'at_capacity_not_on_waiting_list'
      @image_params = { src: 'waiting.png',
                        css_class: 'table_icon mx-auto' }
      @route = 'client_waitings_path'
      @route_params = { wkclass_id: @wkclass.id,
                        purchase_id: @purchase.id,
                        booking_day: @day,
                        booking_section: @booking_section }
      @turbo_params = { method: :post,
                        confirmation: "You'll be added to the waiting list" }
    when 'at_capacity_on_waiting_list'
      waiting = @client.waiting_list_for(@wkclass)
      @image_params = { src: 'remove.png',
                        css_class: 'table_icon mx-auto' }
      @route = 'client_waiting_path'
      @route_params = { id: waiting.id,
                        booking_day: @day,
                        booking_section: @booking_section }
      @turbo_params = { method: :delete,
                        confirmation: "You'll be removed from the waiting list" }
    when 'new_booking'
      confirmation = I18n.t('client.clients.booking.create.confirm')
      confirmation = I18n.t('client.clients.booking.create.confirm_unfreeze') if @purchase.freezed?(@wkclass.start_time)
      @image_params = { src: 'add.png',
                        css_class: "table_icon mx-auto #{'filter-white' unless @wkclass.workout.limited?}" }
      @route = 'client_create_booking_path'
      @route_params = { id: @client.id,
                        booking: { wkclass_id: @wkclass.id, purchase_id: @purchase.id },
                        booking_day: @day,
                        booking_section: @booking_section }
      @turbo_params = { method: :post,
                        confirmation: }
    when 'update_from_booked'
      confirmation = I18n.t('client.clients.booking.update.from_booked.confirm')
      @image_params = { src: 'delete.png',
                        css_class: 'table_icon mx-auto filter-red' }
      @route = 'client_update_booking_path'
      @route_params = { client_id: @client.id,
                        id: @booking.id,
                        booking_day: @day,
                        booking_section: @booking_section }
      @turbo_params = { method: :patch,
                        confirmation: }
    when 'rebook'
      image_class = "table_icon mx-auto #{'filter-white' unless @booking.wkclass.workout.limited?}"
      confirmation = I18n.t('client.clients.booking.update.from_cancelled_early.confirm')
      confirmation = I18n.t('client.clients.booking.update.from_cancelled_early.confirm_unfreeze') if @booking.purchase.freezed?(@booking.wkclass.start_time)
      @image_params = { src: 'add.png',
                        css_class: image_class }
      @route = 'client_update_booking_path'
      @route_params = { client_id: @client.id,
                        id: @booking.id,
                        booking_day: @day,
                        booking_section: @booking_section }
      @turbo_params = { method: :patch,
                        confirmation: }
    end
  end

  def unbookable?(restricted: true)
    return true if @purchase.nil? || !@wkclass.booking_window.cover?(@time)

    return true if @purchase.restricted_on?(@wkclass) && restricted 

    false
  end

  private

  def link_for_new_booking
    return '' if unbookable?(restricted: false)

    return '' if !@on_waiting_list && unbookable?(restricted: true)

    if @wkclass_at_capacity && !@on_waiting_list
      get_params('at_capacity_not_on_waiting_list')
    elsif @wkclass_at_capacity && @on_waiting_list
      get_params('at_capacity_on_waiting_list')
    else
      get_params('new_booking')
    end
    link_maker(@image_params, @route, @route_params, @turbo_params)
  end

  def link_for_update_booking
    return '' if unbookable? # a class legitimately booked, but then auto-cancelled due to expiry date change due to eg freeze break or penalty

    case @booking.status
    when 'booked'
      get_params('update_from_booked')
      link_maker(@image_params, @route, @route_params, @turbo_params)
    when 'cancelled early'
      # class got auto-cancelled due to an event that caused the expiry_date to become earlier (eg a no show penalty or freeze break); @purchase.expiry_date.beginning_of_day will error if not started (eg first booking cancelled early)
      return '' if !@purchase.not_started? && @purchase.expiry_date.beginning_of_day < @wkclass.start_time.beginning_of_day

      if @wkclass_at_capacity && !@on_waiting_list
        get_params('at_capacity_not_on_waiting_list')
      elsif @wkclass_at_capacity && @on_waiting_list
        get_params('at_capacity_on_waiting_list')
      else
        get_params('rebook')
      end
      link_maker(@image_params, @route, @route_params, @turbo_params)
    when 'cancelled late', 'no show'
      ''
    else # 'attended'
      ''
    end
  end

  # ActionController::Base.helpers.link_to '#', class: 'icon-container disable-link' do ActionController::Base.helpers.tag.i class: ["bi bi-battery-full"] end

  def link_maker(image_params, route, route_params, turbo_params)
    # eg af.link_maker({src: 'add.png', css_class: 'table_icon'},'client_waitings_path',{wkclass_id: 1, purchase_id: 5},{method: :post, confirm:  'ok'})
    # "<a data-turbo-method=\"post\" data-turbo-confirm=\"ok\" class=\"icon-container\" href=\"/client/waitings?purchase_id=5&amp;wkclass_id=1\"><img class=\"table_icon\" src=\"/assets/add-8d45e.png\" /></a>"
    ActionController::Base.helpers.link_to(
      ActionController::Base.helpers.image_tag(image_params[:src], class: image_params[:css_class]),
      Rails.application.routes.url_helpers.send(route, route_params),
      data: { turbo_method: turbo_params[:method], turbo_confirm: turbo_params[:confirmation] },
      class: 'icon-container'
    )
  end

  # https://stackoverflow.com/questions/6782978/rails-3-1-determine-if-asset-exists
  def asset_exist?(path)
    if Rails.configuration.assets.compile
      Rails.application.precompiled_assets.include? path
    else
      Rails.application.assets_manifest.assets[path].present?
    end
  end  

end