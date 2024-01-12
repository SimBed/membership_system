class Shared::StrengthMarkersController < Shared::BaseController
  skip_before_action :admin_or_instructor_account
  before_action :admin_or_instructor_or_client_account
  before_action :set_strength_marker, only: [:show, :edit, :update, :destroy]
  before_action :set_client
  before_action :correct_account, only: [:show, :edit, :update, :destroy]
  before_action :initialize_sort, only: :index

  def index
    if logged_in_as? 'client'
      @strength_markers = StrengthMarker.with_client_id(@client.id)
      handle_marker_filter
      handle_sort
      return if @strength_markers.blank?
      StrengthMarker.default_timezone = :utc
      # HACK: hash returned has a key:value pair at each date, but the line_chart doesnt join dots when there are nil values in between, so remove nil values with #compact
      @all_markers_grouped = @strength_markers.unscope(:order)&.group(:name)&.group_by_day(:date)&.average(:weight)&.compact
      StrengthMarker.default_timezone = :local
      prepare_marker_filter
    else
      @strength_markers = StrengthMarker.all
      handle_client_filter
      handle_marker_filter      
      handle_sort
      StrengthMarker.default_timezone = :utc
      @all_markers_grouped = @strength_markers.unscope(:order)&.group(:name)&.group_by_day(:date)&.average(:weight)&.compact
      # hack to fix quirk of date format for column chart
      # https://github.com/ankane/chartkick/issues/352
      @all_markers_grouped.transform_keys!{ |key| [key[0],key[1].strftime("%d %b")] }
      StrengthMarker.default_timezone = :local
      prepare_client_filter
      prepare_marker_filter
    end
  end

  def show; end

  def new
    @strength_marker = StrengthMarker.new
    set_options
  end

  def edit
    set_options
  end

  def create
    @strength_marker = StrengthMarker.new(strength_marker_params)
    if @strength_marker.save
      flash_message :success, t('.success')
      redirect_to shared_strength_markers_path
    else
      set_options
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @strength_marker.update(strength_marker_params)
      flash_message :success, t('.success')
      redirect_to shared_strength_markers_path
    else
      render :edit, status: :unprocessable_entity
    end
  end  

  def destroy
    @strength_marker.destroy
    flash_message :success, t('.success')
    redirect_to shared_strength_markers_path
  end
  
  def filter
    session[:marker_select] = params[:marker_select] || session[:marker_select] 
    unless logged_in_as? 'client'
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

    def handle_client_filter
      return unless session[:client_select].present? && session[:client_select] != 'All'
  
      @strength_markers = @strength_markers.with_client_id(session[:client_select].to_i)
    end    

    def handle_marker_filter
      return unless session[:marker_select].present? && session[:marker_select] != 'All'
  
      @strength_markers = @strength_markers.with_marker_name(session[:marker_select])
    end    

    def set_strength_marker
      @strength_marker = StrengthMarker.find(params[:id])
    end

    def set_client
      return unless logged_in_as? 'client'
      @client = current_account.client
    end

    def set_options
      (@clients = Client.order_by_first_name) unless @client
      @strength_markers = Setting.strength_markers
    end

    def prepare_client_filter
      clients_with_strength_markers = Client.has_strength_marker.order_by_first_name.map { |c| [c.name, c.id] }
      @clients = ['All'] + clients_with_strength_markers
    end

    def prepare_marker_filter
      @markers = ['All'] + Setting.strength_markers.sort
    end

    def strength_marker_params
      params.require(:strength_marker).permit(:name, :weight, :reps, :sets, :date, :note, :client_id)
    end

    def correct_account
      return unless @client

      redirect_to login_path unless @strength_marker.client == @client
    end    
end
