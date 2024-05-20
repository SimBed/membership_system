class Shared::BaseController < ApplicationController
  layout :determine_layout
  before_action :admin_or_instructor_account
  before_action :set_public_timetable # for navigation bar
  before_action :set_admin_status

  private

  def determine_layout
    'admin'
  end

  def set_public_timetable
    @current_timetable = Timetable.find(Rails.application.config_for(:constants)['display_timetable_id'])
  end
end
