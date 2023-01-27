class Superadmin::BaseController < ApplicationController
  layout 'admin'
  before_action :superadmin_account
  before_action :set_public_timetable # for navigation bar

  private
    def set_public_timetable
      # if Rails.env.test?
      #   @timetable = Timetable.first
      # else
      #   @timetable = Timetable.find(Setting.timetable)
      # end
      @timetable = Timetable.find(Setting.timetable)      
    end
end
