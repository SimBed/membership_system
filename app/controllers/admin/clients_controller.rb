class Admin::ClientsController < Admin::BaseController
  skip_before_action :admin_account, only: [:show]
  before_action :correct_account_or_admin, only: [:show]
  # before_action :layout_set, only: [:show]
  before_action :set_client, only: %i[ show edit update destroy ]

  def index
    @clients = Client.order_by_name
  end

  def show
#    session[:attendance_period] = params[:attendance_period] || session[:attendance_period] || Date.today.beginning_of_month.strftime('%b %Y')
    session[:purchaseid] = params[:purchaseid] || session[:purchaseid] || 'All'
    # start_date = Date.parse(session[:attendance_period]).strftime('%Y-%m-%d')
    # end_date = Date.parse(session[:attendance_period]).end_of_month.strftime('%Y-%m-%d')
      if session[:purchaseid] == 'All'
      @purchases = @client.purchases.order_by_dop
      else
      @purchases = [Purchase.find(session[:purchaseid])]
    end if
    @client_hash = {
      attendances: @client.attendances.size,
      spend: @client.total_spend,
      last_class: @client.last_class
    }

    @products_purchased = ['All'] + @client.purchases.order_by_dop.map { |p| [p.name_with_dop, p.id]  }
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
      redirect_to(root_url) unless Client.find(params[:id]).account == current_account || logged_in_as_admin?
    end

    # def layout_set
    #   if logged_in_as_admin?
    #     self.class.layout 'admin'
    #   else
    #     # fails without self.class. Solution given here but reason not known.
    #     # https://stackoverflow.com/questions/33276915/undefined-method-layout-for
    #     self.class.layout 'application'
    #   end
    # end
end
