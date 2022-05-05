class Admin::AdjustmentsController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account  
  before_action :set_adjustment, only: %i[ edit update destroy ]
  after_action -> { update_purchase_status([@purchase]) }, only: %i[ create update destroy ]

  def new
    @adjustment = Adjustment.new
  end

  def create
    @adjustment = Adjustment.new(adjustment_params)

      if @adjustment.save
        @purchase = @adjustment.purchase
        redirect_to admin_purchase_path(Purchase.find(adjustment_params[:purchase_id]))
        flash[:success] = "adjustment was successfully created"
      else
        render :new, status: :unprocessable_entity
      end
  end

  def edit
  end

  def update
    if @adjustment.update(adjustment_params)
      @purchase = @adjustment.purchase
      redirect_to admin_purchase_path(Purchase.find(adjustment_params[:purchase_id]))
      flash[:success] = "adjustment was successfully updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @purchase = @adjustment.purchase
    @adjustment.destroy
    redirect_to admin_purchase_path(@purchase)
    flash[:success] = "adjustment was successfully deleted"
  end

  private

    def set_adjustment
      @adjustment = Adjustment.find(params[:id])
    end

    def adjustment_params
      params.require(:adjustment).permit(:purchase_id, :adjustment, :note)
    end
end
