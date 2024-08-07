class Booking < ApplicationRecord
  include Csv
  belongs_to :wkclass
  belongs_to :purchase
  # allowed to be zero
  has_one :penalty, dependent: :destroy
  # delegate :start_time... defines the start_time method for instances of Attendance
  # so @booking.start_time equals WkClass.find(@booking.id).start_time
  # date is a Wkclass instance method that formats start_time
  validate :purchase_expires_post_start_time
  delegate :start_time, :date, :time, to: :wkclass
  delegate :client, to: :purchase
  delegate :name, to: :client, prefix: :client
  delegate :product, to: :purchase
  scope :in_cancellation_window, -> { joins(:wkclass).merge(Wkclass.in_cancellation_window) }
  scope :during, ->(period) { joins(:wkclass).merge(Wkclass.during(period)) }
  scope :amnesty, -> { where(amnesty: true) }
  scope :no_amnesty, -> { where.not(amnesty: true) }
  scope :confirmed, -> { where(status: Rails.application.config_for(:constants)['booking_statuses'] - ['booked']) }
  scope :attended, -> { where(status: 'attended') }
  scope :committed, -> { where(status: %w[booked attended]) }
  scope :booked, -> { where(status: 'booked') }
  scope :order_by_date, -> { joins(:wkclass).order(start_time: :desc) }
  scope :order_by_status, -> { joins(purchase: [:client]).order(:status, :first_name) }

  validates :status, inclusion: { in: Rails.application.config_for(:constants)['booking_statuses'] }

  class << self
    def applicable_to(wkclass, client)
      joins(:wkclass).where(wkclasses: { id: wkclass.id })
                    .joins([purchase: [:client]])
                    .where(clients: { id: client.id })
                    .first
    end

    def booking_text(group_wkclasses_size, open_gym_wkclasses_size, index)
      inside_window = index <= Setting.booking_window_days_before
      {show_no_group_classes: inside_window && group_wkclasses_size.zero?,
      show_no_opengym_classes: inside_window && open_gym_wkclasses_size.zero?,
      show_not_in_window: !inside_window,
      hide_opengym_section: !inside_window
      }
    end

    
    def by_status(wkclass, status)
      joins(:wkclass, purchase: [:client])
      .where(wkclasses: { id: wkclass.id })
      .where(status:)
      .order(:first_name)
    end
    
    def by_workout_group(workout_group_name, period)
      joins(:wkclass, purchase: [product: [:workout_group]])
      .merge(Wkclass.during(period))
      .where(workout_group_condition(workout_group_name))
      .order(:start_time)
    end
    
    # https://api.rubyonrails.org/v6.1.4/classes/ActiveRecord/QueryMethods.html#method-i-where
    # If an array is passed, then the first element of the array is treated as a template, and the remaining elements are inserted into the template to generate the condition.
    def workout_group_condition(selection)
      ['workout_groups.name = ?', selection.to_s] unless selection == 'All'
    end
  end
  
  def workout_group
    purchase.product.workout_group
  end

  def maxed_out_amendments?
    amendment_count >= Setting.amendment_count
  end

  def purchase_expires_post_start_time
    return unless purchase&.expires_before?(wkclass.start_time.to_date)
    
    errors.add(:base, "The membership of the proposed booking expires before the date of the intended class")
  end  
end
