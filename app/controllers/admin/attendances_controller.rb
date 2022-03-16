class Admin::AttendancesController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account
  before_action :set_attendance, only: %i[ destroy ]

  def new
    session[:wkclass_id] = params[:wkclass_id] || session[:wkclass_id]
    @attendance = Attendance.new
    @wkclass = Wkclass.find(session[:wkclass_id])
    @qualifying_purchases = qualifying_purchases
  end

  def create
    @attendance = Attendance.new(attendance_params)
      if @attendance.save
        redirect_to admin_wkclass_path(@attendance.wkclass, no_scroll: true)
        flash[:success] = "#{@attendance.purchase.client.name}'s attendance was successfully logged"
        #@wkclass = Wkclass.find(params[:attendance][:wkclass_id])
      else
        session[:wkclass_id] = params[:attendance][:wkclass_id] || session[:wkclass_id]
        @attendance = Attendance.new
        @wkclass = Wkclass.find(session[:wkclass_id])
        @qualifying_purchases = qualifying_purchases
        render :new, status: :unprocessable_entity
      end
   end

   def update
     @attendance = Attendance.find(params[:id])
     @wkclass = Wkclass.find(@attendance.wkclass.id)
     @client = @attendance.purchase.client.name
     if @attendance.update(attendance_status_params)
        respond_to do |format|
          format.html do
            flash[:success] = "Attendance was successfully updated"
            redirect_back fallback_location: admin_wkclasses_path
          end
          format.js do
            flash.now[:success] = "#{@client}'s attendance was successfully updated to  #{@attendance.status}"
            render 'admin/wkclasses/update_attendance.js.erb'
          end
        end
     else
       flash[:warning] = "Attendance was not updated"
     end
   end

  def destroy
    @wkclass = Wkclass.find(@attendance.wkclass.id)
    @attendance.destroy
    redirect_to admin_wkclass_path(@wkclass, no_scroll: true)
    flash[:success] = "Attendance was successfully removed"
  end

  # index of attendances not used - available by explicit url but not by navigation link
  def index
    session[:attendance_period] = params[:attendance_period] || session[:attendance_period] || Date.today.beginning_of_month.strftime('%b %Y')
    session[:workout_group] = params[:workout_group] || session[:workout_group] || 'All'
    start_date = Date.parse(session[:attendance_period])
    end_date = Date.parse(session[:attendance_period]).end_of_month.end_of_day
    @attendances = Attendance.by_workout_group(session[:workout_group], start_date, end_date)
    @attendances.sort_by { |a| [a.wkclass.start_time, a.purchase.name] }.reverse!
    @revenue = @attendances.map(&:revenue).inject(0, :+)
    # prepare items for the revenue date select
    # months_logged method defined in application helper
    @months = months_logged
    # prepare items for the workout group select
    @workout_groups = ['All'] + WorkoutGroup.all.map { |wg| ["#{wg.name}"] }
  end

  private

    # e.g. [["Aparna Shah 9C:5W Feb 12", 1], ["Aryan Agarwal UC:3M Jan 31", 2, {class: "close_to_expiry"}], ...]
    def qualifying_purchases
      Purchase.qualifying_for(@wkclass).map do |p|
        close_to_expiry = "close_to_expiry" if p.close_to_expiry? && !p.dropin?
        ["#{p.client.first_name} #{p.client.last_name} #{p.name} #{p.dop.strftime('%b %d')}", p.id, {class: close_to_expiry}]
      end
    end

    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    def attendance_params
      params.require(:attendance).permit(:wkclass_id, :purchase_id)
    end

    def attendance_status_params
      params.require(:attendance).permit(:id, :status)
    end
end
