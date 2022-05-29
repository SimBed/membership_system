class Wkclass < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :confirmed_attendances, lambda {
                                     where(status: Rails.application.config_for(:constants)['attendance_statuses'] - ['booked']).where.not(amnesty: true)
                                   }, class_name: 'Attendance'
  has_many :provisional_attendances, -> { where.not(amnesty: true) }, class_name: 'Attendance'
  has_many :physical_attendances, -> { where(status: 'attended') }, class_name: 'Attendance'
  has_many :purchases, through: :attendances
  has_many :clients, through: :purchases
  belongs_to :instructor
  belongs_to :workout
  validate :instructor_rate_exists
  validate :unique_workout_time_instructor_combo
  delegate :name, to: :workout
  delegate :name, to: :instructor, prefix: true
  scope :order_by_date, -> { order(start_time: :desc) }
  scope :order_by_reverse_date, -> { order(start_time: :asc) }
  scope :has_instructor_cost, -> { where.not(instructor_cost: nil) }
  scope :between, ->(start_date, end_date) { where({ start_time: (start_date..end_date) }).order(:start_time) }
  scope :not_between, ->(start_date, end_date) { where.not({ start_time: (start_date..end_date) }) }
  scope :todays_class, -> { where(start_time: Time.zone.today.all_day) }
  scope :yesterdays_class, -> { where(start_time: Date.yesterday.all_day) }
  scope :tomorrows_class, -> { where(start_time: Date.tomorrow.all_day) }
  scope :on_date, ->(date) { where(start_time: date.all_day) }
  scope :past, -> { where('start_time < ?', Time.zone.now) }
  scope :future, -> { where('start_time > ?', Time.zone.now) }
  visibility_window = 2.hours
  advance_days = 3
  scope :in_booking_visibility_window, lambda {
                                         where({ start_time: ((Time.zone.now - visibility_window)..Date.tomorrow.advance(days: advance_days).end_of_day.to_time) })
                                       }
  cancellation_window = 2.hours
  scope :in_cancellation_window, -> { where('start_time > ?', Time.zone.now + cancellation_window) }
  scope :future_and_recent, -> { where('start_time > ?', Time.zone.now - cancellation_window) }
  paginates_per 100
  # after_create :send_reminder
  # scope :next, ->(id) {where("wkclasses.id > ?", id).last || last}
  # scope :prev, ->(id) {where("wkclasses.id < ?", id).first || first}

  def self.show_in_bookings_for(client)
    Wkclass.in_booking_visibility_window
           .joins(workout: [rel_workout_group_workouts: [workout_group: [products: [purchases: [:client]]]]])
           .where('clients.id': client.id)
           .merge(Purchase.not_fully_expired)
    # .where.not(["attendances.status = ?", 'booked'])
    # .joins(attendances: [purchase: [:client]])
    # .where.not(["clients.id = ? AND attendances.status = ?", client.id, 'booked'])
  end

  # not allowed 2 physical attendances on same day. Used in already_booked_or_attended attendance controller callback
  def booked_or_attended_on_same_day?(client)
    bookings_attendances_on_same_day =
      Wkclass.where.not(id: id).on_date(start_time.to_date).joins(attendances: [purchase: [:client]])
             .where('clients.id = ? AND attendances.status IN (?)', client.id, %w[booked attended])
    return false if bookings_attendances_on_same_day.empty?

    true
  end

  def self.not_already_booked_by2(client)
    Wkclass.future_and_recent.left_joins(attendances: [purchase: [:client]])
           .where.not('clients.id = ? AND attendances.status = ?', client.id, 'booked').or('clients.id IS ?', nil)
  end

  def self.not_already_booked_by(client)
    sql = "SELECT DISTINCT wkclasses.id FROM Wkclasses
           LEFT OUTER JOIN attendances ON wkclasses.id = attendances.wkclass_id
           LEFT OUTER JOIN purchases on attendances.purchase_id = purchases.id
           LEFT OUTER JOIN clients on clients.id = purchases.client_id
           WHERE start_time > '#{2.hours.ago}'
           AND NOT (clients.id = #{client.id} AND attendances.status = 'booked')
           OR clients.id IS NULL;"
    wkclasses = ActiveRecord::Base.connection.exec_query(sql)
    Wkclass.where(id: wkclasses.to_a.map { |r| r['id'] })
  end

  # spent ages trying to work out why a.merge(b) wouldn't work (gave nil result).
  # Ended up with this hack (intersection of 'arrays')
  def self.bookable_by1(client)
    potentially_available_to(client) & not_already_booked_by(client)
  end

  def self.bookable_by(client)
    potentially_bookable_by(client).reject do |wkclass|
      wkclass.day_already_has_booking_by(client)
    end
  end

  def day_already_has_booking_by(client)
    client.attendances.no_amnesty.map do |a|
      a.start_time.to_date
    end
          .include?(start_time.to_date)
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

  def revenue
    attendances.confirmed.map(&:revenue).inject(0, :+)
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

    errors.add(:base, 'Instructor does not have a rate')
  end

  def unique_workout_time_instructor_combo
    wkclass = Wkclass.where(['workout_id = ? and start_time = ? and instructor_id = ?', workout_id, start_time,
                             instructor_id]).first
    return if wkclass.blank?

    errors.add(:base, 'A class for this workout, instructor and time already exists') unless id == wkclass.id
  end
end
