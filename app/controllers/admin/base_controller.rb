class Admin::BaseController < ApplicationController
  layout :determine_layout
  before_action :admin_account
  before_action :set_public_timetable # for navigation bar

  def update_sunset_date(purchases)
    purchases.each do |p|
      p.update(sunset_date: p.sunset_date_calc)
    end
  end

  def set_admin_status
    @admin_plus = logged_in_as?('admin', 'superadmin')
    @junioradmin_plus = logged_in_as?('junioradmin', 'admin', 'superadmin')
    @junioradmin = logged_in_as?('junioradmin')
  end

  private

  def determine_layout
    'admin'
  end

  def set_public_timetable
    @current_timetable = Timetable.find(Rails.application.config_for(:constants)['display_timetable_id'])
  end
end
