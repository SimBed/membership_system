class Admin::AttendancesController < Admin::BaseController
  before_action :set_attendance, only: %i[ edit destroy ]

  def index
    session[:attendance_period] = params[:attendance_period] || session[:attendance_period] || Date.today.beginning_of_month.strftime('%b %Y')
    session[:workout_group] = params[:workout_group] || session[:workout_group] || 'All'
    start_date = Date.parse(session[:attendance_period])
    end_date = Date.parse(session[:attendance_period]).end_of_month.end_of_day
    @attendances = Attendance.by_workout_group(session[:workout_group], start_date, end_date)
    @attendances.sort_by! { |a| [a.wkclass.start_time, a.purchase.name] }.reverse!
    @revenue = @attendances.map(&:revenue).inject(0, :+)
    # prepare items for the revenue date select
    # months_logged method defined in application helper
    @months = months_logged
    # prepare items for the workout group select
    @workout_groups = ['All'] + WorkoutGroup.all.map { |wg| ["#{wg.name}"] }
  end

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
        redirect_to admin_wkclass_path(@attendance.wkclass)
        flash[:success] = "#{@attendance.purchase.client.name}'s attendance was successfully logged"
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
    redirect_to admin_wkclass_path(@wkclass)
    flash[:success] = "Attendance was successfully removed"
  end

  private
    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    def attendance_params
      params.require(:attendance).permit(:wkclass_id, :purchase_id)
    end
end
