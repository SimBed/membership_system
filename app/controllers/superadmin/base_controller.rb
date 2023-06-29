class Superadmin::BaseController < ApplicationController
  layout 'admin'
  before_action :superadmin_account
  before_action :set_public_timetable # for navigation bar

  private

  def set_public_timetable
    @current_timetable = Timetable.find(Rails.application.config_for(:constants)['timetable_id'])
  end
end
