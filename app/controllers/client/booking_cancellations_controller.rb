class Client::BookingCancellationsController < Client::BaseController
    # include BookingsHelper
    # skip_before_action :admin_account
    # before_action :set_booking
    # before_action :correct_account_or_junioradmin_or_instructor_account
    # before_action :set_booking_day, if: -> { client? }
    # before_action :provisionally_expired
    # before_action :modifiable_status
    # before_action :already_committed
    # before_action :reached_max_capacity
    # before_action :reached_max_amendments
    # after_action -> { update_purchase_status([@purchase]) }
  
    # def update
    #   @purchase = @booking.purchase
    #   @wkclass = @booking.wkclass
    #   update_by_client if client?
    #   return unless logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')
  
    #   result = AdminBookingUpdater.new(booking: @booking, wkclass: @wkclass, new_status: booking_status_params[:status]).update
    #   flash_message(*result.flash_array)
    #   update_purchase_status([@purchase]) if result.penalty_change?
    #   return unless result.success?
  
    #   remove_from_waiting_list
    #   notify_waiting_list(@wkclass, triggered_by: 'admin') if ['cancelled early', 'cancelled late'].include? booking_status_params[:status]
    #   handle_admin_update_response
    # end
  
    # def update_by_client
    #   basic_data('client')
    #   action_client_update_too_late && return if @time_of_request == 'too late'
  
    #   send "set_data_client_#{@time_of_request}_cancel"
    #   if @booking.update(status: @updated_status)
    #     action_client_update_success
  
    #     handle_client_update_response
    #   else
    #     flash_client_update_fail
    #   end
    # end
  
    # private
  
    # def client?
    #   logged_in_as?('client')
    # end
  
    # def time_of_request
    #   # only applies to client requests. Admin modifies status directly
    #   # return 'na' if admin_modification?
    #   case @wkclass.start_time - Time.zone.now
    #   when 2.hours.to_i..Float::INFINITY
    #     'early'
    #   when 0..2.hours.to_i
    #     'late'
    #   else
    #     'too late'
    #   end
    # end
  
    # def remove_from_waiting_list
    #   @client.waiting_list_for(@wkclass).destroy if @client.on_waiting_list_for?(@wkclass)
    # end
  
    # # TODO: make dry - repeated in wkclasses controller
    # def notify_waiting_list(wkclass, triggered_by: 'admin')
    #   waitings = wkclass.waitings
    #   return if waitings.empty? || wkclass.in_the_past? || wkclass.at_capacity?
  
    #   waitings.each do |waiting|
    #     flash_message(*Whatsapp.new({ receiver: waiting.purchase.client,
    #                                   message_type: 'waiting_list_blast',
    #                                   triggered_by:,
    #                                   variable_contents: { wkclass_name: wkclass.name,
    #                                                        date_time: wkclass.date_time_short } }).manage_messaging)
    #   end
    # end
  
    # def handle_admin_update_response
    #   set_atendances
    #   flash_message :success, t('.success', name: @booking.client_name, status: @booking.status)
    #   redirect_to wkclass_path(@booking.wkclass, link_from: params[:booking][:link_from], page: params[:booking][:page])
    # end
  
    # def set_atendances
    #   @atendances = @wkclass.atendances.order_by_status
    #   @non_atendances_no_amnesty = @wkclass.non_atendances.no_amnesty.order_by_status
    #   @non_atendances_amnesty = @wkclass.non_atendances.amnesty.order_by_status
    # end  
  
    # def set_booking
    #   @booking = Booking.find(params[:id])
    # end
  
    # def correct_account_or_junioradmin_or_instructor_account
    #   @client = @booking.client
    #   return if current_account?(@client&.account) || logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')
  
    #   flash_message :warning, t('.warning')
    #   redirect_to login_path
    # end
  
    # def provisionally_expired
    #   # eg class shown as bookable, then purchase becomes provsionally expired due to booking of a different class
    #   # either on different browser or by admin, then attempting to book the class shown as bookable on first browser should fail
    #   if new_booking?
    #     handle_provisionally_expired_new_booking
    #   else # update
    #     data_items_provisionally_expired(new_booking: false)
    #     if @purchase.provisionally_expired?
    #       action_client_rebook_cancellation_when_prov_expired if client? && @booking.status != 'booked'
    #       # if the change results in an extra class or validity term reduction
    #       action_admin_rebook_cancellation_when_prov_expired if logged_in_as?('junioradmin', 'admin', 'superadmin') && extra_benefits_after_change?
    #     end
    #   end
    # end  
  
    # # example1 - browser loads, time passes, client logged as no show,
    # # client through browser sends request to cancel booking
    # # example2 - non-browser request to update 'attended' to 'cancelled early'
    # def modifiable_status
    #   # client can never modify attended or no show
    #   return if ['attended', 'no show'].exclude?(@booking.status) || admin_modification?
  
    #   flash_hash = booking_flash_hash[:update][:unmodifiable]
    #   flash_message flash_hash[:colour], (send flash_hash[:message], @booking.status)
    #   # flash[flash_hash[:colour]] =
    #   #   send flash_hash[:message], @booking.status
    #   redirect_to client_book_path(@client)
    # end
  
    # def already_committed
    #   set_wkclass_and_booking_type
    #   return unless @purchase.restricted_on?(@wkclass)
  
    #   flash_hash = booking_flash_hash.dig(@booking_type, :daily_limit_met)
    #   flash_message flash_hash[:colour], (send flash_hash[:message])
    #   # flash_hash[:colour] = send flash_hash[:message]
    #   if client?
    #     redirect_to client_book_path(@client)
    #   else # must be admin
    #     redirect_to wkclass_path(@wkclass)
    #   end
    # end
  
    # def reached_max_capacity
    #   return if admin_modification?
  
    #   set_wkclass_and_booking_type
    #   return unless @wkclass.at_capacity?
  
    #   action_fully_booked(@booking_type) if new_booking? || ['cancelled early',
    #                                                          'cancelled late'].include?(@booking.status)
    # end
  
    # def reached_max_amendments
    #   return unless client? && @booking.maxed_out_amendments?
  
    #   flash_message booking_flash_hash[:update][:prior_amendments][:colour],
    #                 (send booking_flash_hash[:update][:prior_amendments][:message])
    #   redirect_to client_book_path(@client)
    # end
  
    # def new_booking?
    #   return true if request.post?
  
    #   false
    # end
  
    # def data_items_provisionally_expired(new_booking: true)
    #   if new_booking
    #     @purchase = Purchase.find(params.dig(:booking, :purchase_id).to_i)
    #     @wkclass = Wkclass.find(params.dig(:booking, :wkclass_id).to_i)
    #   else # update
    #     @purchase = @booking.purchase
    #   end
    # end
  
    # def admin_modification?
    #   return true if logged_in_as?('junioradmin', 'admin', 'superadmin', 'instructor')
  
    #   false
    # end
    
    # def set_wkclass_and_booking_type
    #   if new_booking?
    #     @booking_type = :booking
    #     @rebooking = false
    #     @wkclass = Wkclass.find(params[:booking][:wkclass_id].to_i)
    #     @purchase = Purchase.find(params.dig(:booking, :purchase_id).to_i)
    #   else
    #     @booking_type = :update
    #     @rebooking = true
    #     @wkclass = @booking.wkclass
    #     @purchase = @booking.purchase
    #   end
    # end
    
    # def booking_status_params
    #   params.require(:booking).permit(:id, :status)
    # end  
  end
