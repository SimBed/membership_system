class Superadmin::BaseController < ApplicationController
  layout 'admin'
  before_action :superadmin_account
  before_action :set_public_timetable # for navigation bar
  before_action :set_admin_status

  private

  def set_public_timetable
    @current_timetable = Timetable.actives_at(Time.zone.now).first    
  end
end
