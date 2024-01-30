class Shared::BodyMarkersController < Shared::BaseController
  skip_before_action :admin_or_instructor_account
  before_action :admin_or_instructor_or_client_account, only: [:index, :new, :filter]
  before_action :set_body_marker, only: [:edit, :update, :destroy]
  before_action :set_client
  before_action :correct_account_or_admin_or_instructor_account, only: [:edit, :create, :update, :destroy]  
  before_action :initialize_sort, only: :index  

  def index
      @body_markers =  @view_all ?  BodyMarker.all : @client.body_markers
      handle_client_filter if @view_all # admin not client
      handle_marker_filter
      handle_sort
      @hide_chart = @body_markers.empty? || @view_all && session[:client_select] == 'All' ? true : false
      unless @body_markers.empty?
        BodyMarker.default_timezone = :utc
        # HACK: hash returned has a key:value pair at each date, but the line_chart doesnt join dots when there are nil values in between, so remove nil values with #compact        
        @all_markers_grouped = @body_markers.unscope(:order)&.group(:bodypart)&.group_by_day(:date)&.average(:measurement)&.compact
        # hack to fix quirk of date format for column chart (but no good on line_chart, unintneded consequence that when dates are not all in same year, shown as year 2001..??)
        # https://github.com/ankane/chartkick/issues/352
        # @all_markers_grouped.transform_keys!{ |key| [key[0],key[1].strftime("%d %b")] }
        BodyMarker.default_timezone = :local
      end
      prepare_client_filter if @view_all # admin not client
      prepare_marker_filter
      handle_pagination
      handle_index_response
  end

  def show; end

  def new
    @body_marker = BodyMarker.new
    set_options
    @form_cancel_link = shared_body_markers_path
  end

  def edit
    set_options
    @form_cancel_link = shared_body_markers_path
  end

  def create
    @body_marker = BodyMarker.new(body_marker_params)
    if @body_marker.save
      flash_message :success, t('.success')
      redirect_to shared_body_markers_path
    else
      set_options
      @form_cancel_link = shared_body_markers_path
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @body_marker.update(body_marker_params)
      flash_message :success, t('.success')
      redirect_to shared_body_markers_path
    else
      set_options
      @form_cancel_link = shared_body_markers_path
      render :edit, status: :unprocessable_entity
    end
  end  

  def destroy
    @body_marker.destroy
    flash_message :success, t('.success')
    redirect_to shared_body_markers_path
  end
  
  def filter
    session[:body_marker_select] = params[:body_marker_select] || session[:body_marker_select] 
    if @view_all
      session[:client_select] = params[:client_select] || session[:client_select] 
    end
    redirect_to shared_body_markers_path
  end  


  private

    def initialize_sort
      session[:body_marker_sort_option] = params[:body_marker_sort_option] || session[:body_marker_sort_option] || 'date'
    end

    def handle_sort
      @body_markers = @body_markers.send("order_by_#{session[:body_marker_sort_option]}")
    end

    def handle_pagination
      @pagy, @body_markers = pagy(@body_markers)
    end  

    def handle_client_filter
      return unless session[:client_select].present? && session[:client_select] != 'All'
  
      @body_markers = @body_markers.with_client_id(session[:client_select])
    end    

    def handle_marker_filter
      return unless session[:body_marker_select].present? && session[:body_marker_select] != 'All'
  
      @body_markers = @body_markers.with_marker_bodypart(session[:body_marker_select])
    end    

    def set_body_marker
      @body_marker = BodyMarker.find(params[:id])
    end

    def set_client
      return unless logged_in_as? 'client'

      @client = current_account.client
      @client_logging = true
    end

    def set_options
      (@clients = Client.order_by_first_name) unless @client_logging
      @body_markers = Setting.body_markers.sort
    end

    def prepare_client_filter
      clients_with_body_markers = Client.has_body_marker.order_by_first_name.map { |c| [c.name, c.id] }
      @clients = ['All'] + clients_with_body_markers
    end

    def prepare_marker_filter
      if @view_all
        @marker_filters = ['All'] + BodyMarker.select(:bodypart).distinct.order(:bodypart).pluck(:bodypart)
      else
        @marker_filters = ['All'] + @client.body_markers.select(:bodypart).distinct.order(:bodypart).pluck(:bodypart)
      end
    end

    def body_marker_params
      params.require(:body_marker).permit(:bodypart, :measurement, :date, :note, :client_id)
    end

    def correct_account_or_admin_or_instructor_account
      return if @view_all #logged_in_as?('admin', 'superadmin', 'instructor')

      @client = if request.post? #create
                  Client.find(params.dig(:body_marker, :client_id).to_i)
                else # edit, update, destroy
                  @body_marker.client
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
