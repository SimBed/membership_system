class WkclassesController < ApplicationController
  before_action :set_wkclass, only: %i[ show edit update destroy ]

  # GET /wkclasses or /wkclasses.json
  def index
    @wkclasses = Wkclass.all
  end

  # GET /wkclasses/1 or /wkclasses/1.json
  def show
  end

  # GET /wkclasses/new
  def new
    @wkclass = Wkclass.new
  end

  # GET /wkclasses/1/edit
  def edit
  end

  # POST /wkclasses or /wkclasses.json
  def create
    @wkclass = Wkclass.new(wkclass_params)

    respond_to do |format|
      if @wkclass.save
        format.html { redirect_to @wkclass, notice: "Wkclass was successfully created." }
        format.json { render :show, status: :created, location: @wkclass }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @wkclass.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /wkclasses/1 or /wkclasses/1.json
  def update
    respond_to do |format|
      if @wkclass.update(wkclass_params)
        format.html { redirect_to wkclasses_path, notice: "Wkclass was successfully updated." }
        format.json { render :show, status: :ok, location: @wkclass }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @wkclass.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /wkclasses/1 or /wkclasses/1.json
  def destroy
    @wkclass.destroy
    respond_to do |format|
      format.html { redirect_to wkclasses_url, notice: "Wkclass was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wkclass
      @wkclass = Wkclass.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def wkclass_params
      params.require(:wkclass).permit(:workout_id, :start_time)
    end
end
