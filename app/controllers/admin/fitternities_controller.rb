class Admin::FitternitiesController < Admin::BaseController
  skip_before_action :admin_account, only: %i[index new create show]
  before_action :junioradmin_account, only: %i[index new create show]
  before_action :set_fitternity, only: %i[show edit update destroy]

  def index
    @fitternities = Fitternity.all
  end

  def show
    @attendances = @fitternity.attendances.order_by_date
  end

  def new
    @fitternity = Fitternity.new
  end

  def edit
  end

  def create
    @fitternity = Fitternity.new(fitternity_params)

    if @fitternity.save
      redirect_to admin_fitternities_path
      flash[:success] = 'Fitternity was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @fitternity.update(fitternity_params)
      redirect_to admin_fitternities_path
      flash[:success] = 'Fitternity was successfully updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @fitternity.destroy
    redirect_to admin_fitternities_path
    flash[:success] = 'Fitternity was successfully destroyed'
  end

  private

  def set_fitternity
    @fitternity = Fitternity.find(params[:id])
  end

  def fitternity_params
    params.require(:fitternity).permit(:max_classes, :expiry_date)
  end
end
