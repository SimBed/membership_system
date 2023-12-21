class Superadmin::OtherServicesController < Superadmin::BaseController
  before_action :set_other_service, only: [:edit, :update, :destroy]

  def index
    @other_services = OtherService.all
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def new
    @other_service = OtherService.new
  end

  def edit; end

  def create
    @other_service = OtherService.new(other_service_params)
    if @other_service.save
      redirect_to superadmin_other_services_path
      flash[:success] = t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @other_service.update(other_service_params)
      redirect_to superadmin_other_services_path
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @other_service.destroy
    redirect_to superadmin_other_services_path
    flash[:success] = t('.success')
  end

  private

  def set_other_service
    @other_service = OtherService.find(params[:id])
  end

  def other_service_params
    params.require(:other_service).permit(:name, :link)
  end
end
