class Admin::FitternitiesController < Admin::BaseController
  skip_before_action :admin_account, only: [:index, :new, :create, :show]
  before_action :junioradmin_account, only: [:index, :new, :create, :show]
  before_action :set_fitternity, only: [:show, :edit, :update, :destroy]

  def index
    @fitternities = Fitternity.order(expiry_date: :desc)
  end

  def show
    @bookings = @fitternity.bookings.order_by_date
  end

  def new
    @fitternity = Fitternity.new
  end

  def edit; end

  def create
    @fitternity = Fitternity.new(fitternity_params)

    if @fitternity.save
      redirect_to fitternities_path
      flash[:success] = t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @fitternity.update(fitternity_params)
      redirect_to fitternities_path
      flash[:success] = t('.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @fitternity.destroy
    redirect_to fitternities_path
    flash[:success] = t('.success')
  end

  private

  def set_fitternity
    @fitternity = Fitternity.find(params[:id])
  end

  def fitternity_params
    params.require(:fitternity).permit(:max_classes, :expiry_date)
  end
end
