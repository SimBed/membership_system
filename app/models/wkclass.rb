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
  has_many :waitings, dependent: :destroy
  belongs_to :instructor
  belongs_to :workout
  belongs_to :instructor_rate
  validate :instructor_rate_exists
  validate :unique_workout_time_instructor_combo
  delegate :name, to: :workout
  delegate :name, to: :instructor, prefix: true
  delegate :rate, to: :instructor_rate
  scope :any_workout_of, ->(workout_filter) { joins(:workout).where(workout: { name: workout_filter }) }
  scope :order_by_date, -> { order(start_time: :desc) }
  scope :order_by_reverse_date, -> { order(start_time: :asc) }
  # deprecate instructor_cost as an attribute of wkclass in due course and reference instructor_rate.rate instead (as below)
  scope :has_instructor_cost, -> { joins(:instructor_rate).where.not(instructor_rate: { rate: 0 }) }
  scope :has_no_instructor_cost, -> { joins(:instructor_rate).where(instructor_rate: { rate: 0 }) }
  # wg is an array of instructor ids
  scope :with_instructor, ->(i) { joins(:instructor).where(instructor: { id: i }) }
  scope :group_by_instructor_cost, -> { joins(:instructor).group("first_name || ' ' || last_name").sum(:instructor_cost) }
  scope :during, ->(period) { where({ start_time: period }).order(:start_time) }
  scope :not_during, ->(period) { where.not({ start_time: period }) }
  scope :todays_class, -> { where(start_time: Time.zone.today.all_day) }
  scope :yesterdays_class, -> { where(start_time: Date.yesterday.all_day) }
  scope :tomorrows_class, -> { where(start_time: Date.tomorrow.all_day) }
  scope :on_date, ->(date) { where(start_time: date.all_day) }
  # scope :past, -> { where('start_time < ?', Time.zone.now) }
  # https://stackoverflow.com/questions/10338596/is-it-possible-to-have-a-scope-with-optional-arguments
  scope :past, ->(months = nil) { months ? where(start_time: (Time.zone.now.advance(months: -months)..Time.zone.now)) : where('start_time < ?', Time.zone.now) }
  scope :future, -> { where('start_time > ?', Time.zone.now) }
  scope :instructorless, -> { where(instructor_id: nil) }
  # comment no longer relevant: unscope order to avoid PG::InvalidColumnReference: ERROR https://stackoverflow.com/questions/42846286/pginvalidcolumnreference-error-for-select-distinct-order-by-expressions-mus
  scope :incomplete, -> { joins(:attendances).where(attendances: { status: 'booked' }).distinct }
  # scope :empty_class, -> { left_joins(:attendances).where(attendances: { id: nil }) }
  # Rubocop recommends
  scope :empty_class, -> { where.missing(:attendances) }
  # limited means multiple bookings in a day restrictions apply ie not Open Gym
  scope :limited, -> { joins(:workout).where(workouts: { limited: true }) }
  scope :unlimited, -> { joins(:workout).where(workouts: { limited: false }) }
  # penalties in last days of Package can cause expiry date to be earlier than final class. Dont want these cases to be considered problematic
  scope :has_booking_post_purchase_expiry, lambda {
                                             joins(attendances: [:purchase])
                                               .where('purchases.expiry_date + 1 < wkclasses.start_time')
                                               .where("attendances.status NOT IN ('no show', 'cancelled late')")
                                           }
  scope :in_booking_visibility_window, -> { where({ start_time: visibility_window }) }
  cancellation_window = Setting.cancellation_window.hours
  scope :in_cancellation_window, -> { where('start_time > ?', Time.zone.now + cancellation_window) }
  scope :future_and_recent, -> { where('start_time > ?', Time.zone.now - cancellation_window) }
  scope :of_service, ->(service) { joins(workout: [:workout_groups]).where(workout_groups: {service: })}
  #  see explantion in Purchase model (not essential right now - could be used in show method of instructors constroller)
  # scope :recover_order, ->(ids) { where(id: ids).order(Arel.sql("POSITION(id::TEXT IN '#{ids.join(',')}')")) }
  # paginates_per Setting.wkclasses_pagination
  # after_create :send_reminder
  # scope :next, ->(id) {where("wkclasses.id > ?", id).last || last}
  # scope :prev, ->(id) {where("wkclasses.id < ?", id).first || first}
  scope :booked_for, ->(client) { joins(attendances: [purchase: [:client]]).where(clients: { id: client.id }).where(attendances: { status: 'booked' }) }

  # would like to use #or method but see difficulties above re structrurally compatible
  # scope :problematic, -> { instructorless.or(self.incomplete).or(self.empty_class.has_instructor_cost) }
  # this method is the 'ruby object' equivalent to the 'raw-sql' approach below

  class << self
    def problematic
      problematic_duration = Setting.problematic_duration
      wkclasses_past = past(problematic_duration)
      wkclasses_past_and_future = during((Time.zone.now.advance(months: -problematic_duration)..Float::INFINITY))
      Wkclass.where(id: problematic_ids(wkclasses_past, wkclasses_past_and_future))
    end

    def instructorless_ids(wkclasses)
      wkclasses.instructorless.map(&:id)
    end

    def incomplete_ids(wkclasses)
      wkclasses.incomplete.map(&:id)
    end

    def empty_with_cost_ids(wkclasses)
      wkclasses.empty_class.has_instructor_cost.map(&:id)
    end

    def booking_post_purchase_expiry(wkclasses)
      wkclasses.has_booking_post_purchase_expiry.map(&:id) # can arise due to careless administration when using the repeat functionality
    end

    def problematic_ids(wkclasses_past, wkclasses_past_and_future)
      instructorless_ids(wkclasses_past) + incomplete_ids(wkclasses_past) + empty_with_cost_ids(wkclasses_past) + booking_post_purchase_expiry(wkclasses_past_and_future)
    end

    # only space group should be client bookable (dont want eg nutrition appearing in client booking table)
    # need a client_bookable attribute in workout_group
    def show_in_bookings_for(client)
      # distinct is needed in case of more than 1 purchase in which case the wkclasses returned will duplicate
      Wkclass.in_booking_visibility_window
             .joins(workout: [rel_workout_group_workouts: [workout_group: [products: [purchases: [:client]]]]])
             .where('clients.id': client.id)
             .where('workout_group.renewable': true)
             .merge(Purchase.not_fully_expired.exclude(Purchase.unexpired_rider_without_ongoing_main))
             .distinct
    end

    def in_workout_group(workout_group_name)
      joins(workout: [rel_workout_group_workouts: [:workout_group]])
        .where(workout_groups: { name: workout_group_name.to_s })
    end

    def visibility_window
      window_start = Time.zone.now - Setting.visibility_window_hours_before.hours
      window_end = Time.zone.now.advance(days: Setting.visibility_window_days_ahead).end_of_day
      (window_start..window_end)
    end

    def start_times
      sql = "SELECT to_char(time_only, 'HH24:MI') FROM (SELECT DISTINCT start_time:: timestamp:: time time_only FROM wkclasses ORDER BY time_only) r;"
      ActiveRecord::Base.connection.exec_query(sql).rows.flatten
    end

    # def any_time_at(times_filter)
    #   sql = "SELECT * from (SELECT *, start_time:: timestamp:: time time_only FROM wkclasses) r where r.time_only IN (#{times_filter.map{|s| "\'#{s}\'"}.join(', ')});"
    #   find_by_sql(sql)
    #   # ActiveRecord::Base.connection.exec_query(sql).rows.flatten
    # end

    def at_time(time)
      return self.all if time == 'All'
      # https://stackoverflow.com/questions/23650313/convert-array-to-string-with-quotes
      sql = "SELECT * from (SELECT *, start_time:: timestamp:: time time_only FROM wkclasses order by start_time DESC) r where r.time_only = #{"\'#{time}\'"}"
      # recover order and return activerecord
      ids = find_by_sql(sql).pluck(:id)
      # need wkclasses.id to avoid ambiguity error
      where(id: ids).order(Arel.sql("POSITION(wkclasses.id::TEXT IN '#{ids.join(',')}')"))
    end
  end

  def committed_on_same_day?(client)
    # Used in already_committed attendances_controller before_action callback
    # fixed packages can be used however the client wants (eg twice a day is ok)
    # unlimited packages not allowed 2 physical attendances on same day, but allowed to cancel or no show and then book another classes
    # (originally for Unlimited we only allowed booking another class after LC or no show if it was an amnesty)
    attendances_on_same_day =
      Wkclass.where.not(id:).on_date(start_time.to_date).joins(attendances: [purchase: [:client]])
             .where(clients: { id: client.id })
             .merge(Attendance.committed)
             .merge(Purchase.unlimited.package)
    return false if attendances_on_same_day.empty?

    true
  end

  def date
    start_time.strftime('%a %d %b %y')
  end

  def time
    start_time.strftime('%H:%M')
  end

  def date_time_short
    start_time.strftime('%H:%M, %a %d')
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
    # Bullet.enable = false if Rails.env == 'development'
    return true if attendances.empty?

    false
    # Bullet.enable = true if Rails.env == 'development'
  end

  def revenue
    attendances.map(&:revenue).inject(0, :+)
  end

  def booking_window
    window_start = start_time.ago(Setting.booking_window_days_before.days).beginning_of_day
    window_end = start_time - Setting.booking_window_minutes_before.minutes
    (window_start..window_end)
  end

  def at_capacity?
    return true if physical_attendances.count >= max_capacity

    false
  end

  def in_the_past?
    return true if Time.zone.now > start_time

    false
  end

  def early_cancelled_pt?
    # where a client cancels a PT session early, the instructor may re-schedule the same class/time combo for a different client
    !workout.group_workout? && attendances&.first&.status == 'cancelled early'
  end

  private

  def instructor_rate_exists
    return unless Instructor.exists?(instructor_id) && instructor.current_rate.nil?

    errors.add(:base, 'Instructor does not have a current rate')
  end

  def unique_workout_time_instructor_combo
    wkclass = Wkclass.where(['workout_id = ? and start_time = ? and instructor_id = ?', workout_id, start_time,
                             instructor_id]).first
    return if wkclass.blank?

    return if wkclass.early_cancelled_pt?

    errors.add(:base, 'A class for this workout, instructor and time already exists') unless id == wkclass.id
  end
end
