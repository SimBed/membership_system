class Superadmin::AnnouncementsController < Superadmin::BaseController
  before_action :set_announcement, only: %i[ show edit update destroy filter clear_filters blast_off remove_client add_client ]

  def index
    @announcements = Announcement.order_by_created_at
  end

  def show
    @recipients = Client.all
    handle_filter
    @addable_clients = Client.exclude(@recipients).order_by_first_name
    set_individually_selected_clients
    @recipient_list_size = @recipients.size
    @pagy_recipients, @recipients = pagy(@recipients, items: Rails.application.config_for(:constants)['recipient_pagination'])
    # https://ddnexus.github.io/pagy/docs/how-to/ Customize the page param
    @pagy_notifieds, @notifieds = pagy(@announcement.clients,  page_param: :notified_page, items: Rails.application.config_for(:constants)['recipient_pagination'])
  end

  def new
    @announcement = Announcement.new
  end

  def edit
  end

  def create
    @announcement = Announcement.new(announcement_params)
    if @announcement.save
      flash[:success] = t('.success')
      redirect_to announcements_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @announcement.update(announcement_params)
      flash[:success] = t('.success')
      redirect_to announcements_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @announcement.destroy
    flash[:success] = t('.success')
    redirect_to announcements_path
  end

  def destroy_notification
    notification = Notification.find(params[:id])
    announcement = notification.announcement
    notification.destroy
    flash[:success] = t('.success')
    redirect_to announcement_path(announcement)    
  end

  def filter
    clear_session(:filter_announcement_packagee, :filter_announcement_group_packagee, :filter_announcement_group_packagee_not_rider,
                  :filter_announcement_has_booking_today, :filter_announcement_has_booking_tomorrow, :filter_announcement_has_booking_in_future,
                  :filter_announcement_nobody)
    set_announcement_session(:packagee, :group_packagee, :group_packagee_not_rider, :has_booking_today, :has_booking_tomorrow, :has_booking_in_future, :nobody)
    redirect_to announcement_path(@announcement)
  end

  def clear_filters
    clear_session(:filter_announcement_packagee,
                  :filter_announcement_group_packagee,
                  :filter_announcement_group_packagee_not_rider,
                  :filter_announcement_has_booking_today,
                  :filter_announcement_has_booking_tomorrow,
                  :filter_announcement_has_booking_in_future,
                  :filter_announcement_nobody,
                  :announcement_client_ids_add, :announcement_client_ids_remove)
    redirect_to announcement_path(@announcement)
  end

  def blast_off
    @recipients = Client.all
    handle_filter
    @recipients -= @announcement.clients
    passes = 0
    errors = 0
    # add_greeting = session[:greeting] == '1' ? true : false 
    @recipients.each do |recipient|
      # recipient_name = add_greeting ? recipient.first_name : nil
      account = recipient.account
      @announcement.notifications.create(account_id: account.id)
      passes += 1
    rescue
      next
      errros += 1
    end
    flash[:success] = t('.success', errors: ActionController::Base.helpers.pluralize(errors, "error"), passes: ActionController::Base.helpers.pluralize(passes, "pass"))
    redirect_to announcement_path(@announcement)
  end  

  def remove_client
    client_id = params[:client_id]
    session[:announcement_client_ids_remove] = client_ids_remove << client_id
    session[:announcement_client_ids_add].delete(client_id)
    redirect_to announcement_path(@announcement)
  end

  def add_client
    client_id = params[:client_id]
    session[:announcement_client_ids_add] = client_ids_add << client_id
    session[:announcement_client_ids_remove].delete(client_id)
    redirect_to announcement_path(@announcement)
  end  

  private

  def client_ids_add
    session[:announcement_client_ids_add] ||= []
  end
  
  def client_ids_remove
    session[:announcement_client_ids_remove] ||= []
  end

  def handle_filter
    %w[packagee group_packagee group_packagee_not_rider has_booking_today has_booking_tomorrow has_booking_in_future nobody].each do |key|
      @recipients = @recipients.send(key) if session["filter_announcement_#{key}"].present?
    end
    unless client_ids_add.empty?
      ids = (client_ids_add + @recipients.unscope(:order).pluck(:id)).uniq
      @recipients = Client.where(id: ids).order_by_first_name
    end
    @recipients = @recipients.where.not(id: @announcement.clients).order_by_first_name
    @recipients = @recipients.where.not(id: client_ids_remove).order_by_first_name
  end

  def set_individually_selected_clients
    @excluded_clients = Client.where(id: client_ids_remove)
    @added_clients = Client.where(id: client_ids_add)    
  end

  #TODO: make dry - see set_session in sessions_helper.rb
  def set_announcement_session(*args)
    args.each do |session_key|
      session["filter_announcement_#{session_key}"] = params[session_key] || session["filter_announcement_#{session_key}"]
    end
  end      

  # Use callbacks to share common setup or constraints between actions.
  def set_announcement
    @announcement = Announcement.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def announcement_params
    # params.fetch(:announcement, {})
    params.require(:announcement).permit(:message)
  end
end
