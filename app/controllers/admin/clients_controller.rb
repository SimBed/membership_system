class Admin::ClientsController < Admin::BaseController
  # skip_before_action :admin_account, only: [:show]
  skip_before_action :admin_account, only: [:index, :new, :edit, :create, :update, :clear_filters, :filter]
  before_action :junioradmin_account, only: [:index, :new, :edit, :create, :update, :clear_filters, :filter]
  # before_action :correct_account_or_admin, only: [:show]
  # before_action :layout_set, only: [:show]
  before_action :set_client, only: [:show, :edit, :update, :destroy]

  def index
    @clients = Client.includes(:account).order_by_name
    handle_search
    handle_filter
    # when exporting data, want it all not just the page of pagination
    handle_export
    handle_index_response
  end

  def show
    # without clearing the session, the following sequence will show the attendances of the purchase of the preiously viewed client:
    # show clientA, select one of clientA's purchases, return to client index, show client B
    clear_session(:purchaseid)
    session[:purchaseid] = params[:purchaseid] || session[:purchaseid] || 'All'
    @purchases = if session[:purchaseid] == 'All'
                   @client.purchases.order_by_dop
                 else
                   [Purchase.find(session[:purchaseid])]
                 end
    set_client_data
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
      flash[:success] = t('.success', name: @client.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @client.update(client_params)
      redirect_to admin_clients_path
      flash[:success] = t('.success', name: @client.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @client.destroy
    redirect_to admin_clients_path
    flash[:success] = t('.success', name: @client.name)
  end

  def clear_filters
    clear_session(:filter_cold, :filter_enquiry, :filter_packagee, :filter_hot, :search_client_name)
    redirect_to admin_clients_path
  end

  def filter
    clear_session(:filter_cold, :filter_enquiry, :filter_packagee, :filter_hot, :search_client_name)
    session[:search_client_name] = params[:search_client_name] || session[:search_client_name]
    set_session(:cold, :enquiry, :packagee, :hot)
    redirect_to admin_clients_path
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:first_name, :last_name, :email, :phone, :instagram, :whatsapp, :hotlead, :note)
  end

  def handle_search
    return if session[:search_client_name].blank?

    @clients = @clients.name_like(session[:search_client_name])
  end

  def handle_filter
    %w[cold enquiry packagee hot].each do |key|
      @clients = @clients.send(key) if session["filter_#{key}"].present?
    end
  end

  def handle_export
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
      format.csv { send_data @clients.to_csv }
      format.xls
    end
  end

  def set_client_data
    @client_hash = {
      attendances: @client.attendances.size,
      purchases: @client.purchases.size,
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
