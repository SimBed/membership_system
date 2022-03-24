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
  scope :has_instructor_cost, -> { where.not(instructor_cost: nil) }
  scope :between, ->(start_date, end_date) { where({ start_time: (start_date..end_date) }).order(:start_time) }
  scope :not_between, ->(start_date, end_date) { where.not({ start_time: (start_date..end_date) }) }
  scope :todays_class, -> { where(start_time: Date.today.beginning_of_day..Date.today.end_of_day)}
  scope :yesterdays_class, -> { where(start_time: Date.yesterday.beginning_of_day..Date.yesterday.end_of_day)}
  scope :tomorrows_class, -> { where(start_time: Date.tomorrow.beginning_of_day..Date.tomorrow.end_of_day)}
  scope :past, -> { where('start_time < ?', Date.today.beginning_of_day) }
  scope :future, -> { where.not(id: past) }
  paginates_per 100
  # scope :next, ->(id) {where("wkclasses.id > ?", id).last || last}
  # scope :prev, ->(id) {where("wkclasses.id < ?", id).first || first}

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

  def summary
    "#{workout.name}, #{date}, #{time}"
  end

  def revenue
    attendances.confirmed.map { |a| a.revenue }.inject(0, :+)
  end

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
