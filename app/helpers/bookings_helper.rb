module BookingsHelper
  def booking_day_name(index, day)
    return 'today'.capitalize if index.zero?
    return 'tomorrow'.capitalize if index == 1

    day.strftime('%a').capitalize
  end
    
  def booking_flash_hash
    { booking:
      { successful:
        { colour: :success,
          message: :successful },
        fully_booked:
        { colour: :secondary,
          message: :fully_booked },
        daily_limit_met:
        { colour: :secondary,
          message: :daily_limit_met },
        too_late:
        { colour: :secondary,
          message: :too_late },
        unsuccessful:
        { colour: :secondary,
          message: :unsuccessful },
        already_booked:
        { colour: :secondary,
          message: :already_booked },
        provisionally_expired:
        { colour: :secondary,
          message: :provisionally_expired } },
      update:
      { successful:
        { colour: :success,
          message: :successful },
        fully_booked:
        { colour: :secondary,
          message: :fully_booked },
        daily_limit_met:
        { colour: :secondary,
          message: :daily_limit_met },
        too_late:
        { colour: :secondary,
          message: :too_late },
        cancel_early:
        { colour: :primary,
          message: :cancel_early },
        cancel_late_amnesty:
        { colour: :primary,
          message: :cancel_late_amnesty },
        cancel_late_no_amnesty:
        { colour: :danger,
          message: :cancel_late_no_amnesty },
        prior_amendments:
        { colour: :secondary,
          message: :prior_amendments },
        unmodifiable:
        { colour: :secondary,
          message: :unmodifiable },
        unsuccessful:
        { colour: :secondary,
          message: :unsuccessful } } }
  end

  def successful(wkclass_name, wkclass_day)
    "Booked for #{wkclass_name} on #{wkclass_day}"
  end

  def fully_booked(re = false)
    "#{re ? 'Reb' : 'B'}ooking not possible. Class fully booked"
  end

  def daily_limit_met
    'Booking not possible. Daily limit met'
  end

  def already_booked
    'Booking not possible. You have already booked this class'
  end

  def provisionally_expired
    ['The maximum number of classes has already been booked.',
    'Renew you Package if you wish to attend this class']
  end

  def too_late(update = false, wkclass = '')
    if update
      "Booking for #{wkclass} not changed. Deadline to make changes has passed"
    else
      'Booking not possible. Not in booking window'
    end
  end

  def unsuccessful(update = false)
    ["Booking #{update ? 'was not updated' : 'failed'}. Refresh browser and try again.",
     'If this recurs, please contact The Space']
  end

  def cancel_early(wkclass_name, wkclass_day)
    ["#{wkclass_name} on #{wkclass_day} is 'cancelled early'",
     'There is no deduction for this change.']
  end

  def cancel_late_amnesty(wkclass_name, wkclass_day)
    ["#{wkclass_name} on #{wkclass_day} is 'cancelled late'",
     'There is no deduction for this change this time.',
     'Avoid deductions by making changes to bookings before the deadlines']
  end

  def cancel_late_no_amnesty(wkclass_name, wkclass_day)
    ["#{wkclass_name} on #{wkclass_day} is 'cancelled late'",
     'A deduction will be made to your Package.',
     'Avoid deductions by making changes to bookings before the deadlines']
  end

  def prior_amendments
    ['Change not possible. Too many prior amendments.',
     'Please contact the Space for help']
  end

  def unmodifiable(status)
    ["Booking is '#{status}' and can't now be changed.",
     'Please contact the Space for help']
  end
end
