class Shared::StrengthMarkersController < Shared::BaseController
  skip_before_action :admin_or_instructor_account
  before_action :admin_or_instructor_or_client_account, only: [:index, :new, :filter]
  before_action :set_strength_marker, only: [:edit, :update, :destroy]
  before_action :set_client
  before_action :correct_account_or_admin_or_instructor_account, only: [:edit, :create, :update, :destroy]  
  before_action :initialize_sort, only: :index

  def index
      @strength_markers =  @client_logging ? @client.strength_markers : StrengthMarker.all
      handle_client_filter unless @client_logging
      handle_marker_filter      
      handle_sort
      prepare_client_filter unless @client_logging
      prepare_marker_filter
      handle_pagination
      handle_index_response
  end

  def new
    @strength_marker = StrengthMarker.new
    set_options
    @form_cancel_link = shared_strength_markers_path
  end

  def edit
    set_options
    @form_cancel_link = shared_strength_markers_path        
  end

  def create
    @strength_marker = StrengthMarker.new(strength_marker_params)
    if @strength_marker.save
      flash_message :success, t('.success')
      redirect_to shared_strength_markers_path
    else
      set_options
      @form_cancel_link = shared_strength_markers_path
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @strength_marker.update(strength_marker_params)
      flash_message :success, t('.success')
      redirect_to shared_strength_markers_path
    else
      set_options
      @form_cancel_link = shared_strength_markers_path
      render :edit, status: :unprocessable_entity
    end
  end  

  def destroy
    @strength_marker.destroy
    flash_message :success, t('.success')
    redirect_to shared_strength_markers_path
  end
  
  def filter
    session[:strength_marker_select] = params[:strength_marker_select] || session[:strength_marker_select] 
    unless @client_logging
      session[:client_select] = params[:client_select] || session[:client_select] 
    end
    redirect_to shared_strength_markers_path
  end  

  private

    def initialize_sort
      session[:strength_marker_sort_option] = params[:strength_marker_sort_option] || session[:strength_marker_sort_option] || 'date'
    end

    def handle_sort
      @strength_markers = @strength_markers.send("order_by_#{session[:strength_marker_sort_option]}")
    end

    def handle_pagination
      @pagy, @strength_markers = pagy(@strength_markers)
    end      

    def handle_client_filter
      return unless session[:client_select].present? && session[:client_select] != 'All'
  
      @strength_markers = @strength_markers.with_client_id(session[:client_select])
    end    

    def handle_marker_filter
      return unless session[:strength_marker_select].present? && session[:strength_marker_select] != 'All'

      @strength_markers = @strength_markers.with_marker_name(session[:strength_marker_select])
    end    

    def set_strength_marker
      @strength_marker = StrengthMarker.find(params[:id])
    end

    def set_client
      return unless logged_in_as? 'client'

      @client = current_account.client
      @client_logging = true
    end

    def set_options
      (@client_options = Client.order_by_first_name) unless @client_logging
      @strength_marker_options = Setting.strength_markers.sort
    end

    def prepare_client_filter
      clients_with_strength_markers = Client.has_strength_marker.order_by_first_name.map { |c| [c.name, c.id] }
      @client_filters = ['All'] + clients_with_strength_markers
    end

    def prepare_marker_filter
      if @client_logging
        @marker_filters = ['All'] + @client.strength_markers.select(:name).distinct.order(:name).pluck(:name)
      else
        @marker_filters = ['All'] + StrengthMarker.select(:name).distinct.order(:name).pluck(:name)
      end
    end

    def strength_marker_params
      params.require(:strength_marker).permit(:name, :weight, :reps, :sets, :date, :note, :client_id)
    end

    def correct_account_or_admin_or_instructor_account
      return if logged_in_as?('admin', 'superadmin', 'instructor')

      @client = if request.post? #create
                  Client.find(params.dig(:strength_marker, :client_id).to_i)
                else # edit, update, destroy
                  @strength_marker.client
                end
      return if current_account?(@client&.account)
  
      flash_message :warning, t('.warning')
      redirect_to login_path
    end

    def handle_index_response
      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end
end
