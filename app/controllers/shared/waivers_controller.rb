class Shared::WaiversController < Shared::BaseController
  skip_before_action :admin_or_instructor_account
  before_action :set_client, except: [:index] 
  before_action :set_waiver, only: [:edit, :show, :update] 

  def index
    @waivers = Waiver.order_by_date
  end

  def new
    @waiver = Waiver.new
    @form_cancel_link = new_client_waiver_path(@client)
  end

  def create
    @waiver = Waiver.new(waiver_params)
    if @waiver.save
      flash_message :success, t('.success')
      redirect_to client_book_path(@client)
    else
      @form_cancel_link = new_client_waiver_path(@client)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @form_cancel_link = waivers_path
  end

  def update
    if @waiver.update(waiver_params)
      flash_message :success, t('.success')
      redirect_to waivers_path
    else
      @form_cancel_link = waivers_path
      render :edit, status: :unprocessable_entity
    end
  end  

  def show
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_waiver
    @waiver = @client.waiver
  end

  def waiver_params
    params.require(:waiver).permit(:tear, :pcos, :none, :menopausal, :fertility, :injury, :injury_note, :heart_trouble,
                                   :chest_pain, :doctors_permit, :signed, :client_id)
  end

end