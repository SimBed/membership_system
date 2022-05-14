class Admin::FreezesController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :set_freeze, only: %i[edit update destroy]
  after_action -> { update_purchase_status([@purchase]) }, only: %i[create update destroy]

  def new
    @freeze = Freeze.new
  end

  def create
    @freeze = Freeze.new(freeze_params)
    if @freeze.save
      @purchase = @freeze.purchase
      redirect_to admin_purchase_path(Purchase.find(freeze_params[:purchase_id]))
      flash[:success] = 'freeze was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @freeze.update(freeze_params)
      @purchase = @freeze.purchase
      redirect_to admin_purchase_path(Purchase.find(freeze_params[:purchase_id]))
      flash[:success] = 'freeze was successfully updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase = @freeze.purchase
    @freeze.destroy
    redirect_to admin_purchase_path(@purchase)
    flash[:success] = 'freeze was successfully deleted'
  end

  private

  def set_freeze
    @freeze = Freeze.find(params[:id])
  end

  def freeze_params
    params.require(:freeze).permit(:purchase_id, :start_date, :end_date, :note)
  end
end
