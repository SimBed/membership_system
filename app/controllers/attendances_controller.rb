class AttendancesController < ApplicationController
  before_action :set_attendance, only: %i[ edit destroy ]

  def new
    session[:wkclass_id] = params[:wkclass_id] || session[:wkclass_id]
    @attendance = Attendance.new
    @wkclass = Wkclass.find(session[:wkclass_id])
    # e.g. [["Aparna Shah 9C:5W", 1], ["Aryan Agarwal UC:3M", 2], ...]
    @qualifying_products = Wkclass.clients_with_product(@wkclass).map { |q| ["#{Client.find(q["clientid"]).first_name} #{Client.find(q["clientid"]).last_name} #{Purchase.find(q["purchaseid"]).name}", q["purchaseid"]] }
  end

  def create
    @attendance = Attendance.new(attendance_params)
      if @attendance.save
        redirect_to new_attendance_path, notice: "#{@attendance.rel_user_product.user.name}''s attendance was successfully logged."
        @wkclass = Wkclass.find(params[:attendance][:wkclass_id])
      else
        session[:wkclass_id] = params[:attendance][:wkclass_id] || session[:wkclass_id]
        @attendance = Attendance.new
        @wkclass = Wkclass.find(session[:wkclass_id])
        @qualifying_products = Wkclass.clients_with_product(@wkclass).map { |q| ["#{Client.find(q["clientid"]).first_name} #{Client.find(q["clientid"]).last_name} #{Purchase.find(q["purchaseid"]).name}", q["purchaseid"]] }
        render :new, status: :unprocessable_entity
      end
   end

  def destroy
    @wkclass = Wkclass.find(@attendance.wkclass.id)
    @attendance.destroy
    redirect_to @wkclass, notice: "Attendance was successfully removed."
  end

  private
    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    def attendance_params
      params.require(:attendance).permit(:wkclass_id, :purchase_id)
    end
end
