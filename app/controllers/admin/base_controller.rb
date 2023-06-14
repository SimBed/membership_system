class Admin::BaseController < ApplicationController
  layout :determine_layout
  before_action :admin_account
  before_action :set_public_timetable # for navigation bar

  def update_purchase_status(purchases)
    # this has to be done as separate requests as each calc is dependent on the previously updated attribute
    # this could be avoided and done as one update request with some reformatting of the calc methods (to include an optional argument)
    purchases.each do |p|
      orig_status = p.status
      p.update(start_date: p.start_date_calc)
      p.update(expiry_date: p.expiry_date_calc)
      p.update(status: p.status_calc)
      status_changed = orig_status != p.status ? true : false
      # NOTE: rider = nil would return false, so this means if p is a rider then set rider p.rider and carry out the conditional, otherwise dont
      if rider = p.rider_purchase
        # the rider cant continue once the main has expired
        rider.update(status: 'expired', expiry_date: p.expiry_date) if p.expired? && !rider.expired?
        # conceivably the rider can be reactivated from expired if a change is made to the main that brings the main back from expired
        rider.update(status: rider.status_calc) if !p.expired? && status_changed
      end
    end
  end

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
    @current_timetable = Timetable.find(Setting.timetable)
  end
end
