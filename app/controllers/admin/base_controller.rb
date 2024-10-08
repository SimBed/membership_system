class Admin::BaseController < ApplicationController
  layout :determine_layout
  before_action :admin_account
  before_action :set_public_timetable # for navigation bar
  before_action :set_admin_status

  def update_sunset_date(purchases)
    purchases.each do |p|
      p.update(sunset_date: p.sunset_date_calc)
    end
  end

  private

  def determine_layout
    'admin'
  end

  def set_public_timetable
    @current_timetable = Timetable.actives_at(Time.zone.now).first
  end
end
