class ClientsController < ApplicationController
  before_action :set_client, only: %i[ show edit update destroy ]

  def index
    @clients = Client.all
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
        redirect_to clients_path
        flash[:success] = "#{@client.name} was successfully added"
      else
        render :new, status: :unprocessable_entity
      end
  end

  def update
      if @client.update(client_params)
        redirect_to clients_path
        flash[:success] = "#{@client.name} was successfully updated"
      else
        render :edit, status: :unprocessable_entity
      end
  end

  def destroy
    @client.destroy
      redirect_to clients_url
      flash[:success] = "#{@client.name} was successfully deleted"
  end

  private
    def set_client
      @client = Client.find(params[:id])
    end

    def client_params
      params.require(:client).permit(:first_name, :last_name, :email, :phone)
    end
end
