class Wkclass < ApplicationRecord
  include Csv
  # want settings hash from ApplicationHelper
  include ApplicationHelper
  has_many :attendances, dependent: :destroy
  # https://docs.rubocop.org/rubocop-rails/cops_rails.html#railsinverseof
  # rubocop likes dependent and inverse_of to be specified even though they seem superfluous here
  has_many :physical_attendances, lambda {
                                    where(status: %w[booked attended])
                                  }, class_name: 'Attendance', dependent: :destroy, inverse_of: :wkclass
  has_many :ethereal_attendances, lambda {
                                    where.not(status: %w[booked attended])
                                  }, class_name: 'Attendance', dependent: :destroy, inverse_of: :wkclass
  has_many :purchases, through: :attendances
  has_many :clients, through: :purchases
  belongs_to :instructor
  belongs_to :workout
  validate :instructor_rate_exists
  validate :unique_workout_time_instructor_combo
  validate :pt_instructor
  delegate :name, to: :workout
  delegate :name, to: :instructor, prefix: true
  scope :any_workout_of, ->(workout_filter) { joins(:workout).where(workout: { name: workout_filter }) }
  scope :order_by_date, -> { order(start_time: :desc) }
  scope :order_by_reverse_date, -> { order(start_time: :asc) }
  scope :has_instructor_cost, -> { where.not(instructor_cost: nil) }
  scope :group_by_instructor_cost, -> { joins(:instructor).group("first_name || ' ' || last_name").sum(:instructor_cost) }
  scope :during, ->(period) { where({ start_time: period }).order(:start_time) }
  scope :not_during, ->(period) { where.not({ start_time: period }) }
  scope :todays_class, -> { where(start_time: Time.zone.today.all_day) }
  scope :yesterdays_class, -> { where(start_time: Date.yesterday.all_day) }
  scope :tomorrows_class, -> { where(start_time: Date.tomorrow.all_day) }
  scope :on_date, ->(date) { where(start_time: date.all_day) }
  scope :past, -> { where('start_time < ?', Time.zone.now) }
  scope :future, -> { where('start_time > ?', Time.zone.now) }
  scope :instructorless, -> { past.where(instructor_id: nil) }
  # scope :incomplete, -> { past.joins(:attendances).where("attendances.status= 'booked'") }
  scope :incomplete, -> { past.joins(:attendances).where(attendances: {status: 'booked'}) }
  # visibility_window = 2.hours
  # advance_days = 3
  # scope :in_booking_visibility_window, lambda {
  #                                        window_start = Time.zone.now - visibility_window
  #                                        window_end = Date.tomorrow.advance(days: advance_days).end_of_day.to_time
  #                                        where({ start_time: (window_start..window_end) })
  #                                      }
  scope :in_booking_visibility_window, -> { where({ start_time: visibility_window }) }
  cancellation_window = 2.hours
  scope :in_cancellation_window, -> { where('start_time > ?', Time.zone.now + cancellation_window) }
  scope :future_and_recent, -> { where('start_time > ?', Time.zone.now - cancellation_window) }
  paginates_per 100
  # after_create :send_reminder
  # scope :next, ->(id) {where("wkclasses.id > ?", id).last || last}
  # scope :prev, ->(id) {where("wkclasses.id < ?", id).first || first}

  # only space group should be client bookable (dont want eg nutrition appearing in client booking table)
  # need a client_bookable attribute in workout_group
  def self.show_in_bookings_for(client)
    # distinct is needed in case of more than 1 purchase in which case the wkclasses returned will duplicate
    Wkclass.in_booking_visibility_window
           .joins(workout: [rel_workout_group_workouts: [workout_group: [products: [purchases: [:client]]]]])
           .where('clients.id': client.id)
           .where('workout_group.id': 1)
           .merge(Purchase.not_fully_expired)
           .distinct
  end

  # not allowed 2 physical attendances on same day. Used in already_committed attendance controller callback
  # def booked_or_attended_on_same_day?(client)
  #   bookings_attendances_on_same_day =
  #     Wkclass.where.not(id: id).on_date(start_time.to_date).joins(attendances: [purchase: [:client]])
  #            .where('clients.id = ? AND attendances.status IN (?)', client.id, %w[booked attended])
  #   return false if bookings_attendances_on_same_day.empty?
  #
  #   true
  # end

  # def committed_on_same_day?(client)
  #   # fixed packages can be used however the client wants (eg twice a day is ok)
  #   non_amnesty_attendances_on_same_day =
  #     Wkclass.where.not(id: id).on_date(start_time.to_date).joins(attendances: [purchase: [:client]])
  #            .where('clients.id = ? AND attendances.amnesty = false', client.id)
  #            .merge(Purchase.unlimited.package)
  #   return false if non_amnesty_attendances_on_same_day.empty?
  #
  #   true
  # end

  def committed_on_same_day?(client)
    # Used in already_committed attendances_controller before_action callback
    # fixed packages can be used however the client wants (eg twice a day is ok)
    # unlimited packages not allowed 2 physical attendances on same day, but allowed to cancel or no show and then book another classes
    # (originally for Unlimited we only allowed booking another class after LC or no show if it was an amnesty)
    attendances_on_same_day =
      Wkclass.where.not(id: id).on_date(start_time.to_date).joins(attendances: [purchase: [:client]])
             .where('clients.id = ?', client.id)
             .merge(Attendance.committed)
             .merge(Purchase.unlimited.package)
    return false if attendances_on_same_day.empty?

    true
  end

  def self.in_workout_group(workout_group_name)
    joins(workout: [rel_workout_group_workouts: [:workout_group]])
      .where(workout_groups: { name: workout_group_name.to_s })
  end

  def date
    start_time.strftime('%a %d %b %y')
  end

  def time
    start_time.strftime('%H:%M')
  end

  def day_of_week
    start_time.strftime('%A')
  end

  def summary
    "#{workout.name}, #{date}, #{time}"
  end

  def table_name
    return name unless workout.instructor_initials?

    "#{name} (#{instructor.initials})"
  end

  def deletable?
    return true if attendances.empty?

    false
  end
  
  def revenue
    attendances.map(&:revenue).inject(0, :+)
  end

  def booking_window
    settings = Rails.application.config_for(:constants)['settings']
    window_start = start_time.ago(settings[:booking_window_days_before].days).beginning_of_day
    window_end = start_time - settings[:booking_window_minutes_before].minutes
    (window_start..window_end)
  end

  def self.visibility_window
    settings = Rails.application.config_for(:constants)['settings']
    window_start = Time.zone.now - settings[:visibility_window_hours_before].hours
    window_end = Time.zone.now.advance(days: settings[:visibility_window_days_ahead]).end_of_day
    (window_start..window_end)
  end

  def at_capacity?
    return true if physical_attendances.count >= max_capacity

    false
  end

  # Use a class method with an argument to call send_reminder method rather than call send_reminder directly
  # on an wkclass instance. As Delayed::Job works by saving an object to database (in yml form), this approach considerably
  # reduces the volume of data stored in the delayed_jobs table (per Railscast)
  class << self
    def send_reminder(id)
      find(id).send_reminder
    end
    # handle_asynchronously :send_reminder, run_at: proc { Time.zone.now + 30.seconds }
    handle_asynchronously :send_reminder, run_at: proc { 30.seconds.from_now }
  end

  def send_reminder
    # file_path = "#{Rails.root}/delayed.txt"
    file_path = Rails.root.join('delayed.txt')
    File.write(file_path, "delayed job processing at #{Time.zone.now}")
    # Wkclass.last.update(instructor_cost:100)
    # account_sid = Rails.configuration.twilio[:account_sid]
    # auth_token = Rails.configuration.twilio[:auth_token]
    # from = Rails.configuration.twilio[:whatsapp_number]
    # to = Rails.configuration.twilio[:me]
    # client = Twilio::REST::Client.new(account_sid, auth_token)
    # time_str = ((self.start_time).localtime).strftime("%I:%M%p on %b. %d, %Y")
    # self.attendances.no_amnesty.each do |booking|
    #     body = "Hi #{self.purchase.client.first_name}. Just a reminder that you have a class coming up at #{time_str}."
    #     message = client.messages.create(
    #       from: "whatsapp:#{from}",
    #       to: "whatsapp:#{to}",
    #       body: body
    #     )
    #   end
  end
  # handle_asynchronously :send_reminder, :run_at => Proc.new { |i| i.when_to_run }

  # def when_to_run
  #   minutes_before_class = 60.minutes
  #   start_time - minutes_before_class
  # end
  private

  def instructor_rate_exists
    return unless Instructor.exists?(instructor_id) && instructor.current_rate.nil?

    errors.add(:base, 'Instructor does not have a current rate')
  end

  def unique_workout_time_instructor_combo
    wkclass = Wkclass.where(['workout_id = ? and start_time = ? and instructor_id = ?', workout_id, start_time,
                             instructor_id]).first
    return if wkclass.blank?

    errors.add(:base, 'A class for this workout, instructor and time already exists') unless id == wkclass.id
  end

  def pt_instructor
    return unless Instructor.exists?(instructor_id)

    if ('PT'.in? name) && !('PT'.in? instructor.name)
      errors.add(:base, 'Personal Training must have a PT instructor') unless [1,2].include? instructor.id # Apoorv, Gigi 
    end

    if !('PT'.in? name) && ('PT'.in? instructor.name)
      errors.add(:base, 'PT instructor only available for PT')
    end

  end
end
