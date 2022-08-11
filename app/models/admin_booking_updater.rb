class AdminBookingUpdater
  include AttendancesHelper

# line77 in attendances_controller
# flash_message AdminBookingUpdater.new(attendance: @attendance, wkclass: @wkclass, new_status: attendance_status_params[:status] ).update if logged_in_as?('junioradmin', 'admin', 'superadmin')

  def initialize(attributes = {})
    @attendance = attributes[:attendance]
    @wkclass = attributes[:wkclass]
    @new_status = attributes[:new_status]
    @old_status = @attendance.status
    @purchase = @attendance.purchase
    @penalty_change = false
    @flash_array = [nil]
  end

  def update
    if @attendance.update(status: @new_status)
      action_admin_update_success
      return OpenStruct.new(success?: true, penalty_change?: @penalty_change, flash_array: @flash_array )
    else
      @flash_array = [:warning, I18n.t('admin.attendances.update_by_admin.warning')]
      return OpenStruct.new(success?: false, penalty_change?: @penalty_change, flash_array: @flash_array )
    end
  end

  def action_admin_update_success
    @attendance.increment!(:amendment_count)
    action_undo_cancel(@old_status) if ['cancelled early', 'cancelled late', 'no show'].include? @old_status
    if ['cancelled early', 'cancelled late', 'no show'].include? @new_status
      action_cancel(@new_status)
    else # attended or a rebook (which always count)
      @attendance.update(amnesty: false)
      handle_freeze
    end
  end

  def action_cancel(new_status)
    cancel_attribute = self.class.status_map(new_status)
    @purchase.increment!(cancel_attribute)
    if @purchase.send(cancel_attribute) > amnesty_limit[@purchase.product_style][cancel_attribute][@purchase.product_type]
      # typically will already be false eg booked to no show, but could be correction of eg cancellation early (with amnesty) to cancellation late (without amnesty)
      @attendance.update(amnesty: false)
      cancellation_penalty @purchase.product_type, cancel_attribute: cancel_attribute
    else
      @attendance.update(amnesty: true)
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
    unless @attendance.penalty.nil?
      @attendance.penalty.destroy
      @penalty_change = true
    end
  end

  def cancellation_penalty(package_type, cancel_attribute: :early_cancels)
    return unless package_type == :unlimited_package && @attendance.reload.penalty.nil?
      Penalty.create({ purchase_id: @purchase.id, attendance_id: @attendance.id,
                       amount: amnesty_limit[:group][cancel_attribute][:penalty][:amount],
                       reason: @new_status })
      @penalty_change = true
      @flash_array = Whatsapp.new(whatsapp_params("#{cancel_attribute}_penalty")).manage_messaging
  end

  def handle_freeze
    wkclass_datetime = @attendance.wkclass.start_time
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
      message_type: message_type,
      variable_contents: { name:  @wkclass.name, day: @wkclass.day_of_week } }
  end

  def self.status_map(status)
    # status is of form 'cancelled early'
    status_map = { cancelled_early: :early_cancels, cancelled_late: :late_cancels, no_show: :no_shows }
    status_map[status.split.join('_').to_sym]
  end
end
