class Wkclass < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :confirmed_attendances, -> { where(status: Rails.application.config_for(:constants)["attendance_status_does_count"].reject { |a| a == 'booked'}) }, class_name: 'Attendance'
  has_many :provisional_attendances, -> { where(status: Rails.application.config_for(:constants)["attendance_status_does_count"]) }, class_name: 'Attendance'
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
  scope :todays_class, -> { where(start_time: Date.today.beginning_of_day..Date.today.end_of_day)}
  scope :yesterdays_class, -> { where(start_time: Date.yesterday.beginning_of_day..Date.yesterday.end_of_day)}
  scope :tomorrows_class, -> { where(start_time: Date.tomorrow.beginning_of_day..Date.tomorrow.end_of_day)}
  scope :on_date, ->(date) { where(start_time: date.beginning_of_day..date.end_of_day)}
  scope :past, -> { where('start_time < ?', Time.now) }
  scope :future, -> { where('start_time > ?', Time.now) }
  visibility_window = 2.hours
  advance_days = 1
  scope :in_booking_visibility_window, -> { where({ start_time: ( (Time.now - visibility_window)..Date.tomorrow.advance(days: advance_days).end_of_day.to_time) })}
  cancellation_window = 2.hours
  scope :in_cancellation_window, -> { where('start_time > ?', Time.now + cancellation_window) }
  scope :future_and_recent, -> { where('start_time > ?', Time.now - cancellation_window) }
  paginates_per 100
  # after_create :send_reminder
  # scope :next, ->(id) {where("wkclasses.id > ?", id).last || last}
  # scope :prev, ->(id) {where("wkclasses.id < ?", id).first || first}

  def self.show_in_bookings_for(client)
    Wkclass.in_booking_visibility_window
    .joins(workout: [rel_workout_group_workouts: [workout_group: [products: [purchases: [:client]]]]])
    .where("clients.id": client.id)
    .merge(Purchase.not_expired)
    #.where.not(["attendances.status = ?", 'booked'])
    # .joins(attendances: [purchase: [:client]])
    # .where.not(["clients.id = ? AND attendances.status = ?", client.id, 'booked'])
  end

  def booking_on_same_day?(client)
    bookings_on_same_day =
    Wkclass.where.not(id: self.id).on_date(self.start_time.to_date).joins(attendances: [purchase: [:client]])
    .where("clients.id = ? AND attendances.status IN (?)", client.id, Rails.application.config_for(:constants)["attendance_status_cant_rebook"])
    return false if bookings_on_same_day.empty?
    return true
  end

  def self.not_already_booked_by2(client)
    Wkclass.future_and_recent.left_joins(attendances: [purchase: [:client]])
    .where.not("clients.id = ? AND attendances.status = ?", client.id, 'booked').or("clients.id IS ?", nil)
  end

  def self.not_already_booked_by(client)
    sql = "SELECT DISTINCT wkclasses.id FROM Wkclasses
           LEFT OUTER JOIN attendances ON wkclasses.id = attendances.wkclass_id
           LEFT OUTER JOIN purchases on attendances.purchase_id = purchases.id
           LEFT OUTER JOIN clients on clients.id = purchases.client_id
           WHERE start_time > '#{Time.now - 2.hours}'
           AND NOT (clients.id = #{client.id} AND attendances.status = 'booked')
           OR clients.id IS NULL;"
    wkclasses = ActiveRecord::Base.connection.exec_query(sql)
    Wkclass.where(id: wkclasses.to_a.map {|r| r['id']})
  end

  # spent ages trying to work out why a.merge(b) wouldn't work (gave nil result).
  # Ended up with this hack (intersection of 'arrays')
  def self.bookable_by1(client)
    self.potentially_available_to(client) & self.not_already_booked_by(client)
  end

  def self.bookable_by(client)
    self.potentially_bookable_by(client).select do |wkclass|
      !wkclass.day_already_has_booking_by(client)
    end
  end

  def day_already_has_booking_by(client)
    client.attendances.provisional.map do |a|
      a.start_time.to_date
    end
    .include?(self.start_time.to_date)
  end

  def self.in_workout_group(workout_group_name)
     joins(workout: [rel_workout_group_workouts: [:workout_group]])
    .where("workout_groups.name = ?", "#{workout_group_name}")
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
    attendances.confirmed.map { |a| a.revenue }.inject(0, :+)
  end

  # Use a class method with an argument to call send_reminder method rather than call send_reminder directly
  # on an wkclass instance. As Delayed::Job works by saving an object to database (in yml form), this approach considerably
  # reduces the volume of data stored in the delayed_jobs table (per Railscast)
  class << self
    def send_reminder(id)
      find(id).send_reminder
    end
    handle_asynchronously :send_reminder, :run_at => Proc.new { Time.now + 30.seconds }
  end

  def send_reminder
    file_path = "#{Rails.root}/delayed.txt"
    File.open(file_path, 'w') do |file|
      file.write("delayed job processing at #{Time.now}")
    end
    # Wkclass.last.update(instructor_cost:100)
    # account_sid = Rails.configuration.twilio[:account_sid]
    # auth_token = Rails.configuration.twilio[:auth_token]
    # from = Rails.configuration.twilio[:whatsapp_number]
    # to = Rails.configuration.twilio[:me]
    # client = Twilio::REST::Client.new(account_sid, auth_token)
    # time_str = ((self.start_time).localtime).strftime("%I:%M%p on %b. %d, %Y")
    # self.attendances.provisional.each do |booking|
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
      errors.add(:base, "Instructor does not have a rate") if Instructor.exists?(instructor_id) && instructor.current_rate.nil?
    end

    def unique_workout_time_instructor_combo
      wkclass = Wkclass.where(["workout_id = ? and start_time = ? and instructor_id = ?", workout_id, start_time, instructor_id])
      wkclass.each do |w|
        if id != wkclass.first.id
          errors.add(:base, "A class for this workout, instructor and time already exists") if wkclass.present?
          return
        end
      end
    end


end
