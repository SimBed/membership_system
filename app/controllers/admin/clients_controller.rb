class Admin::ClientsController < Admin::BaseController
  # skip_before_action :admin_account, only: [:show]
  skip_before_action :admin_account, only: [:index, :new, :edit, :create, :update, :clear_filters, :filter]
  before_action :junioradmin_account, only: [:index, :new, :edit, :create, :update, :clear_filters, :filter]
  before_action :initialize_sort, only: :index
  # before_action :layout_set, only: [:show]
  before_action :set_client, only: [:show, :edit, :update, :destroy]

  def index
    @clients = Client.includes(:account)
    handle_search
    handle_filter
    handle_sort
    handle_export
    handle_index_response
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
      # flash[:success] = t('.success', name: @client.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    update_account_email = true unless @client.email == client_params[:email] || @client.account.nil?
    if @client.update(client_params)
      @client.account.update(email: @client.email) if update_account_email
      redirect_to admin_clients_path
      flash_message :success, t('.success', name: @client.name)
      # flash[:success] = t('.success', name: @client.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to admin_clients_path
    flash_message :success, t('.success', name: @client.name)
    # flash[:success] = t('.success', name: @client.name)
  end

  def clear_filters
    clear_session(:filter_cold, :filter_enquiry, :filter_packagee, :filter_active, :search_client_name)
    redirect_to admin_clients_path
  end

  def filter
    clear_session(:filter_cold, :filter_enquiry, :filter_packagee, :filter_active, :search_client_name)
    session[:search_client_name] = params[:search_client_name] || session[:search_client_name]
    set_session(:cold, :enquiry, :packagee, :active)
    redirect_to admin_clients_path
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    # the update method (and therefore the client_params method) is used through a form but also clicking on a link on the clients page
    return {fitternity: params[:fitternity] } if params[:fitternity].present?
    return {waiver: params[:waiver] } if params[:waiver].present?

    params.require(:client).permit(:first_name, :last_name, :email, :phone, :instagram, :whatsapp, :hotlead, :note)
  end

  def initialize_sort
    session[:client_sort_option] = params[:client_sort_option] || session[:client_sort_option] || 'first_name'
  end

  def handle_search
    return if session[:search_client_name].blank?

    @clients = @clients.name_like(session[:search_client_name])
  end

  def handle_filter
    %w[cold enquiry packagee active].each do |key|
      @clients = @clients.send(key) if session["filter_#{key}"].present?
    end
  end

  def handle_sort
    @clients = @clients.send("order_by_#{session[:client_sort_option]}").page params[:page]
  end

  def handle_export
    # when exporting data, want it all not just the page of pagination
    @clients = if params[:export_all]
                 @clients.page(params[:page]).per(1000)
               else
                 @clients.page params[:page]
               end
  end

  def handle_index_response
    respond_to do |format|
      format.html
      format.js { render 'index.js.erb' }
      # Railscasts #362 Exporting Csv And Excel
      # https://www.youtube.com/watch?v=SelheZSdZj8
      format.csv { send_data @clients.to_csv }
      format.xls
    end
  end

  def prepare_data_for_view
    @client_hash = {
      attendances: @client.attendances.attended.size,
      packages: @client.purchases.package.size,
      dropins: @client.purchases.dropin.size,
      spend: @client.total_spend,
      last_class: @client.last_class,
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
