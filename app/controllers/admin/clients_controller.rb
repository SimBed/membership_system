class Admin::ClientsController < Admin::BaseController
  # skip_before_action :admin_account, only: [:show]
  skip_before_action :admin_account, only: [:index, :new, :edit, :create, :update, :clear_filters, :filter, :show]
  before_action :junioradmin_account, only: [:index, :new, :edit, :create, :update, :clear_filters, :filter, :show]
  before_action :initialize_sort, only: :index
  # before_action :layout_set, only: [:show]
  before_action :set_client, only: [:show, :edit, :update, :destroy]
  before_action :set_raw_numbers, only: :edit
  before_action :set_admin_status, only: [:index, :update]

  def index
    # this must be inefficient, loading all clients and their associations into memory
    @clients = Client.includes(:account, :purchases)
    handle_filter
    # switched order cos of bug with chaining scope with group by in it (previously handle search before handle filter)
    handle_search
    handle_sort
    handle_pagination
    handle_index_response
  end

  def analyze
    @clients = Client.includes(:account, :purchases)
    handle_filter
    handle_search
    handle_sort
    handle_pagination
  end

  def show
    # without clearing the session, the following sequence will show the attendances of the purchase of the preiously viewed client:
    # show clientA, select one of clientA's purchases, return to client index, show client B
    # no longer want selection
    # clear_session(:purchaseid)
    # session[:purchaseid] = params[:purchaseid] || session[:purchaseid] || 'All'
    # @packages = if session[:purchaseid] == 'All'
    #                @client.purchases.package.order_by_dop
    #              else
    #                [Purchase.find(session[:purchaseid])]
    #              end
    @ongoing_packages = @client.purchases.not_fully_expired.package.order_by_dop
    @ongoing_dropins = @client.purchases.not_fully_expired.dropin.order_by_dop
    @expired_purchases = @client.purchases.fully_expired.order_by_dop
    prepare_data_for_view
    set_show_dropdown_items
  end

  def new
    @client = Client.new
  end

  def edit; end

  def create
    @client = Client.new(client_params)
    if @client.save
      redirect_to admin_clients_path
      flash_message :success, t('.success', name: @client.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # if the client email is updated, the account email must be too
    # neeed to add an extra conditional (or use if client_params[:email].nil?) as shouldn't update email on waiver/instagram toggle)
    update_account_email = true unless @client.email == client_params[:email] || @client.account.nil?
    if @client.update(client_params)
      # @client.account.update(email: @client.email) if update_account_email
      @client.account.update_column(:email, @client.email) if update_account_email
      if client_params[:email].nil? # means not the update form, but a link to update waiver or instagram
        respond_to do |format|
          format.html { redirect_back fallback_location: admin_clients_path, success: t('.success', name: @client.name) }
          format.turbo_stream { flash_message :success, t('.success', name: @client.name), true }
        end
      else
        # redirect_to admin_client_path(@client)
        redirect_to admin_clients_path
        flash_message :success, t('.success', name: @client.name)
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to admin_clients_path
    flash_message :success, t('.success', name: @client.name)
  end

  def clear_filters
    clear_session(:filter_cold, :filter_enquiry, :filter_packagee, :filter_active, :filter_one_time_trial, :search_client_name, :search_client_number)
    redirect_to admin_clients_path
  end

  def filter
    clear_session(:filter_cold, :filter_enquiry, :filter_packagee, :filter_active, :filter_one_time_trial, :search_client_name, :search_client_number)
    session[:search_client_name] = params[:search_client_name] || session[:search_client_name]
    session[:search_client_number] = params[:search_client_number] || session[:search_client_number]
    set_session(:cold, :enquiry, :packagee, :active, :one_time_trial)
    redirect_to admin_clients_path
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def set_raw_numbers
    @client.phone_country_code = @client.country_code
    @client.whatsapp_country_code = @client.country(:whatsapp)
    @client.phone_raw = @client.number_raw
    @client.whatsapp_raw = @client.number_raw(:whatsapp)
  end

  def client_params
    # the update method (and therefore the client_params method) is used through a form but also clicking on a link on the clients page
    return { fitternity: params[:fitternity] } if params[:fitternity].present?
    return { waiver: params[:waiver] } if params[:waiver].present?
    return { instawaiver: params[:instawaiver] } if params[:instawaiver].present?
    return { whatsapp_group: params[:whatsapp_group] } if params[:whatsapp_group].present?

    # modifier_is_client is necessary so validation of Client model can vary from admin to client (ie new signups through the web must provide more robust data)
    params.require(:client).permit(:first_name, :last_name, :email, :whatsapp_country_code, :whatsapp_raw, :phone_raw, :instagram, :hotlead, :student, :friends_and_family, :note)
          .merge(phone_country_code: 'IN')
          .merge(modifier_is_client: false)
  end

  def initialize_sort
    session[:client_sort_option] = params[:client_sort_option] || session[:client_sort_option] || 'first_name'
    session[:client_sort_option] = params[:client_sort_option] || session[:client_sort_option] || 'first_name'
  end

  def handle_search
    handle_name_search
    handle_number_search
  end

  def handle_name_search
    return if session[:search_client_name].blank?

    @clients = @clients.name_like(session[:search_client_name])
  end

  def handle_number_search
    return if session[:search_client_number].blank?

    @clients = @clients.number_like(session[:search_client_number])
  end

  def handle_filter
    %w[cold enquiry packagee active one_time_trial].each do |key|
      @clients = @clients.send(key) if session["filter_#{key}"].present?
    end
  end

  def handle_sort
    @clients = @clients.send("order_by_#{session[:client_sort_option]}") #.page params[:page]
  end

  def handle_pagination
    # when exporting data, want it all not just the page of pagination
    if params[:export_all]
    #  @clients.page(params[:page]).per(100_000)
      @pagy, @clients = pagy(@clients, items: 100_000)
    else
    #  @clients.page params[:page]
      @pagy, @clients = pagy(@clients)
    end
  end

  def handle_index_response
    respond_to do |format|
      format.html
      # Railscasts #362 Exporting Csv And Excel
      # https://www.youtube.com/watch?v=SelheZSdZj8
      format.csv { send_data @clients.to_csv }
      format.xls
      format.turbo_stream
    end
  end

  def prepare_data_for_view
    @client_hash = {
      attendances: @client.attendances.attended.size,
      packages: @client.purchases.package.size,
      dropins: @client.purchases.dropin.size,
      spend: @client.total_spend,
      last_counted_class: @client.last_counted_class,
      date_created: @client.created_at,
      date_last_purchase_expiry: @client.last_purchase&.expiry_date
    }
  end

  def set_show_dropdown_items
    @products_purchased = ['All'] + @client.purchases.order_by_dop.map { |p| [p.name_with_dop, p.id] }
  end
  # def layout_set
  #   if logged_in_as?('admin')
  #     self.class.layout 'admin'
  #   else
  #     # fails without self.class. Solution given here but reason not known.
  #     # https://stackoverflow.com/questions/33276915/undefined-method-layout-for
  #     self.class.layout 'application'
  #   end
  # end
end
