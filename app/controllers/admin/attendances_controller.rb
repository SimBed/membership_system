class Admin::AttendancesController < Admin::BaseController
  skip_before_action :admin_account
  before_action :junioradmin_account
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

    @qualifying_purchases = Wkclass.clients_with_purchase_for(@wkclass).map do |q|
      client = Client.find(q["clientid"])
      purchase = Purchase.find(q["purchaseid"])
      close_to_expiry = "close_to_expiry" if purchase.close_to_expiry? && !purchase.dropin?
      ["#{client.first_name} #{client.last_name} #{purchase.name} #{purchase.dop.strftime('%b %d')}", q["purchaseid"], {class: close_to_expiry}]
     end
    # e.g. [["Aparna Shah 9C:5W Feb 12", 1], ["Aryan Agarwal UC:3M Jan 31", 2], ...]
    # @qualifying_purchases = Purchase.qualifying_for(@wkclass).map do |p|
    #   ["#{p.client.first_name} #{p.client.last_name} #{p.name} #{p.dop.strftime('%b %d')}", p.id]
    #  end
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
        @qualifying_purchases = Purchase.qualifying_for(@wkclass).map do |p|
          ["#{p.client.first_name} #{p.client.last_name} #{p.name} #{p.dop.strftime('%b %d')}", p.id]
         end
        render :new, status: :unprocessable_entity
      end
   end

   def update
     @attendance = Attendance.find(params[:attendance][:id])
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

    def attendance_status_params
      params.require(:attendance).permit(:id, :status)
    end
end
