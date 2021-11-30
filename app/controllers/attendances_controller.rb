#require 'byebug'
class AttendancesController < ApplicationController
  before_action :set_attendance, only: %i[ show edit update destroy ]

  # GET /attendances or /attendances.json
  def index
    @attendances = Attendance.all
  end

  # GET /attendances/1 or /attendances/1.json
  def show
  end

  # GET /attendances/new
  def new
    session[:wkclass_id] = params[:wkclass_id] || session[:wkclass_id]
    @attendance = Attendance.new
    @wkclass = Wkclass.find(session[:wkclass_id])
    # e.g. [["Aparna Shah 9C:5W", 1], ["Aryan Agarwal UC:3M", 2], ...]
    @qualifying_products = Wkclass.users_with_product(@wkclass).map { |q| ["#{User.find(q["userid"]).first_name} #{User.find(q["userid"]).last_name} #{RelUserProduct.find(q["relid"]).name}", q["relid"]] }
  end

  # GET /attendances/1/edit
  def edit
  end

  # POST /attendances or /attendances.json
  def create
    @attendance = Attendance.new(attendance_params)
    #byebug
    respond_to do |format|
      if @attendance.save
        format.html { redirect_to @attendance, notice: "Attendance was successfully created." }
        format.json { render :show, status: :created, location: @attendance }
        @wkclass = Wkclass.find(params[:attendance][:wkclass_id])
      else
        session[:wkclass_id] = params[:attendance][:wkclass_id] || session[:wkclass_id]
        @attendance = Attendance.new
        @wkclass = Wkclass.find(session[:wkclass_id])
        @qualifying_products = Wkclass.users_with_product(@wkclass).map { |q| ["#{User.find(q["userid"]).first_name} #{User.find(q["userid"]).last_name} #{RelUserProduct.find(q["relid"]).name}", q["relid"]] }
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @attendance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /attendances/1 or /attendances/1.json
  def update
    respond_to do |format|
      if @attendance.update(attendance_params)
        format.html { redirect_to @attendance, notice: "Attendance was successfully updated." }
        format.json { render :show, status: :ok, location: @attendance }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @attendance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attendances/1 or /attendances/1.json
  def destroy
    @attendance.destroy
    respond_to do |format|
      format.html { redirect_to attendances_url, notice: "Attendance was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def attendance_params
      params.require(:attendance).permit(:wkclass_id, :rel_user_product_id)
    end
end
