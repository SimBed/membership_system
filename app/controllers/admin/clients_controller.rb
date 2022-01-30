class Admin::ClientsController < Admin::BaseController
  skip_before_action :admin_account, only: [:show]
  before_action :correct_account_or_admin, only: [:show]
  before_action :layout_make, only: [:show]
  before_action :set_client, only: %i[ show edit update destroy ]

  def index
    @clients = Client.order_by_name
  end

  def show
    session[:attendance_period] = params[:attendance_period] || session[:attendance_period] || Date.today.beginning_of_month.strftime('%b %Y')
    start_date = Date.parse(session[:attendance_period]).strftime('%Y-%m-%d')
    end_date = Date.parse(session[:attendance_period]).end_of_month.strftime('%Y-%m-%d')
    @attendances = Attendance.by_client(@client.id, start_date, end_date)
    # @client_hash = {
    #   number: attendances.size,
    #   base_revenue: base_revenue,
    #   expiry_revenue: expiry_revenue,
    #   total_revenue: base_revenue + expiry_revenue
    # }
    @months = months_logged
  end

  def new
    @client = Client.new
  end

  def edit
  end

  def create
    @client = Client.new(client_params)
      if @client.save
        redirect_to admin_clients_path
        flash[:success] = "#{@client.name} was successfully added"
      else
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @client.update(client_params)
        redirect_to admin_clients_path
        flash[:success] = "#{@client.name} was successfully updated"
      else
        render :edit, status: :unprocessable_entity
      end
  end

  def destroy
    @client.destroy
      redirect_to admin_clients_path
      flash[:success] = "#{@client.name} was successfully deleted"
  end

  private
    def set_client
      @client = Client.find(params[:id])
    end

    def client_params
      params.require(:client).permit(:first_name, :last_name, :email, :phone, :instagram)
    end

    def correct_account
      redirect_to referrer unless Client.find(params[:id]).account == current_account
    end

    def correct_account_or_admin
      redirect_to(root_url) unless Client.find(params[:id]).account == current_account || current_account&.admin? || current_account&.superadmin?
    end

    def layout_make
      if logged_in_as_admin?
        self.class.layout 'admin'
      else
        # fails without self.class. Solution given here but reason not known.
        # https://stackoverflow.com/questions/33276915/undefined-method-layout-for
        self.class.layout 'application'
      end
    end
end
