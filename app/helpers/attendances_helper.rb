module AttendancesHelper
  def booking_flash_hash
    { booking:
      { successful:
        { colour: :success,
          message: :successful
        },
        fully_booked:
        { colour: :secondary,
          message: :fully_booked
        },
        daily_limit_met:
        { colour: :secondary,
          message: :daily_limit_met
        },
        too_late:
        { colour: :secondary,
          message: :too_late
        },
        unsuccessful:
        { colour: :secondary,
          message: :unsuccessful
        },
      },
      update:
      { successful:
        { colour: :success,
          message: :successful
        },
        fully_booked:
        { colour: :secondary,
          message: :fully_booked
        },
        daily_limit_met:
        { colour: :secondary,
          message: :daily_limit_met
        },
        too_late:
        { colour: :secondary,
          message: :too_late
        },
        cancel_early:
        { colour: :primary,
          message: :cancel_early
        },
        cancel_late_amnesty:
        { colour: :primary,
          message: :cancel_late_amnesty
        },
        cancel_late_no_amnesty:
        { colour: :danger,
          message: :cancel_late_no_amnesty
        },
        prior_amendments:
        { colour: :secondary,
          message: :prior_amendments
        },
        unmodifiable:
        { colour: :secondary,
          message: :unmodifiable
        },
        unsuccessful:
        { colour: :secondary,
          message: :unsuccessful
        },
      }
    }
  end

  def successful(wkclass_name, wkclass_day)
    "Booked for #{wkclass_name} on #{wkclass_day}"
  end

  def fully_booked(re = false)
    "#{re ? 'Reb' : 'B'}ooking not possible. Class fully booked"
  end

  def daily_limit_met
    "Booking not possible. Daily limit met"
  end

  def too_late(update = false, wkclass = '')
    if update
      "Booking for #{wkclass} not changed. Deadline to make changes has passed"
    else
      "Booking not possible. Not in booking window"
    end
  end

  def unsuccessful(update = false)
    ["Booking #{update ? 'was not updated' : 'failed'}. Refresh browser and try again.",
     "If this recurs, please contact The Space"]
  end

  def cancel_early(wkclass_name, wkclass_day)
    ["#{wkclass_name} on #{wkclass_day} is 'cancelled early'",
     "There is no deduction for this change."]
  end

  def cancel_late_amnesty(wkclass_name, wkclass_day)
    ["#{wkclass_name} on #{wkclass_day} is 'cancelled late'",
     "There is no deduction for this change this time.",
     "Avoid deductions by making changes to bookings before the deadlines"]
  end

  def cancel_late_no_amnesty(wkclass_name, wkclass_day)
    ["#{wkclass_name} on #{wkclass_day} is 'cancelled late'",
     "A deduction will be made to your Package.",
     "Avoid deductions by making changes to bookings before the deadlines"]
  end

  def prior_amendments
    ["Change not possible. Too many prior amendments.",
     "Please contact the Space for help"]
  end

  def unmodifiable(status)
    ["Booking is '#{status}' and can't now be changed.",
     "Please contact the Space for help"]
  end

  delegate :dropin?, to: :product
  delegate :trial?, to: :product
  delegate :unlimited_package?, to: :product
  delegate :fixed_package?, to: :product

  def amnesty_limit
    { cancel_late:
        { unlimited_package: 2,
          fixed_package: 1,
          trial: 100,
          dropin: 1
        },
      no_show:
        { unlimited_package: 1,
          fixed_package: 0,
          trial: 100,
          dropin: 0
        }
    }
  end

  def settings
    {amendment_count: 3}
  end
end
