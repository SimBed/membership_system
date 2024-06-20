class AdminBookingUpdater
  include BookingsHelper
  Outcome = Struct.new(:success?, :penalty_change?, :flash_array)

  def initialize(attributes = {})
    @booking = attributes[:booking]
    @wkclass = attributes[:wkclass]
    @new_status = attributes[:new_status]
    @old_status = @booking.status
    @purchase = @booking.purchase
    @penalty_change = false
    @flash_array = [nil]
  end

  def update
    if @booking.update(status: @new_status)
      action_admin_update_success
      # OpenStruct.new(success?: true, penalty_change?: @penalty_change, flash_array: @flash_array)
      Outcome.new(true, @penalty_change, @flash_array)
    else
      @flash_array = [:warning, I18n.t('admin.bookings.update_by_admin.warning')]
      # OpenStruct.new(success?: false, penalty_change?: @penalty_change, flash_array: @flash_array)
      Outcome.new(false, @penalty_change, @flash_array)
    end
  end

  def action_admin_update_success
    @booking.increment!(:amendment_count)
    action_undo_cancel(@old_status) if ['cancelled early', 'cancelled late', 'no show'].include? @old_status
    if ['cancelled early', 'cancelled late', 'no show'].include? @new_status
      action_cancel(@new_status)
    else # attended or a rebook (which always count)
      @booking.update(amnesty: false)
      handle_freeze
    end
  end

  def action_cancel(new_status)
    cancel_attribute = self.class.status_map(new_status)
    @purchase.increment!(cancel_attribute)
    # previously amnesty_limit was a hash in BookingssHelper, now it's a method of the Setting class.
    # if @purchase.send(cancel_attribute) > amnesty_limit[@purchase.product_style][cancel_attribute][@purchase.product_type]
    if @purchase.send(cancel_attribute) > Setting.amnesty_limit[@purchase.product_style][cancel_attribute][@purchase.product_type]
      # typically will already be false eg booked to no show, but could be correction of eg cancellation early (with amnesty) to cancellation late (without amnesty)
      @booking.update(amnesty: false)
      cancellation_penalty @purchase.product_type, cancel_attribute:
    else
      @booking.update(amnesty: true)
      @flash_array = Whatsapp.new(whatsapp_params("#{cancel_attribute}_no_penalty")).manage_messaging
    end
  end

  def action_undo_cancel(old_status)
    # Ideally we would like to disriminate between corrections and changes:
    # e.g. an admin change from CL to attended could be a correction or could be a reality.
    # In the latter case, techincally any penalty should stand, however we will treat it as an admin correction
    # and delete any associated penalty. Edge and not of serious consequence.
    cancel_attribute = self.class.status_map(old_status)
    @purchase.decrement!(cancel_attribute)
    return if @booking.penalty.nil?

    @booking.penalty.destroy
    @penalty_change = true
  end

  def cancellation_penalty(package_type, cancel_attribute: :early_cancels)
    return unless package_type == :unlimited_package && @booking.reload.penalty.nil?

    Penalty.create({ purchase_id: @purchase.id, booking_id: @booking.id,
                     amount: Setting.amnesty_limit[:group][cancel_attribute][:penalty][:amount],
                     reason: @new_status })
    @penalty_change = true
    @flash_array = Whatsapp.new(whatsapp_params("#{cancel_attribute}_penalty")).manage_messaging
  end

  def handle_freeze
    wkclass_datetime = @booking.wkclass.start_time
    # unlikley to be more than 1, but you never know
    applicable_freezes = @purchase.freezes_cover(wkclass_datetime)
    return if applicable_freezes.empty?

    applicable_freezes.each do |f|
      # wish to bypass validation, else would just use update method
      f.end_date = wkclass_datetime.advance(days: -1).to_date
      f.save(validate: false)
    end
  end

  def whatsapp_params(message_type)
    { receiver: @purchase.client,
      message_type:,
      variable_contents: { name: @wkclass.name, day: @wkclass.day_of_week } }
  end

  def self.status_map(status)
    # status is of form 'cancelled early'
    status_map = { cancelled_early: :early_cancels, cancelled_late: :late_cancels, no_show: :no_shows }
    status_map[status.split.join('_').to_sym]
  end
end
