class Attendance < ApplicationRecord
  belongs_to :wkclass
  belongs_to :purchase
  # delegate :start_time... defines the start_time method for instances of Attendance
  # so @attendance.start_time equals WkClass.find(@attendance.id).start_time
  # date is a Wkclass instance method that formats start_time
  delegate :start_time, :date, :time, to: :wkclass
  delegate :client, to: :purchase
  delegate :name, to: :client
  delegate :product, to: :purchase
  scope :in_cancellation_window, -> { joins(:wkclass).merge(Wkclass.in_cancellation_window)}
  scope :confirmed, -> { where(status: Rails.application.config_for(:constants)["attendance_status_does_count"].reject { |a| a == 'booked'}) }
  scope :provisional, -> { where(status: Rails.application.config_for(:constants)["attendance_status_does_count"]) }
  scope :order_by_date, -> { joins(:wkclass).order(start_time: :desc) }
  validates :status, inclusion: { in:
    Rails.application.config_for(:constants)["attendance_status_does_count"] +
    Rails.application.config_for(:constants)["attendance_status_doesnt_count"]
    }

  def self.applicable_to(wkclass, client)
     joins(:wkclass).where("wkclasses.id = ?", wkclass.id)
    .joins([purchase: [:client]])
    .where("clients.id = ?", client.id)
    .first
  end

  def revenue
    purchase.payment / purchase.attendance_estimate
  end

  def workout_group
    purchase.product.workout_group
  end

  def self.by_status(wkclass, status)
     # sort_order = Rails.application.config_for(:constants)["attendance_status"]
     joins(:wkclass, purchase: [:client])
    .where(wkclasses: {id: wkclass.id})
    .where(status: status)
    .order(:first_name)
    # .select('attendances.status', 'clients.first_name')
    #.to_a.sort_by { |a| [sort_order.index(a.status), a.first_name] }
  end

  def self.by_workout_group(workout_group_name, start_date, end_date)
      joins(:wkclass, purchase: [product: [:workout_group]])
     .merge(Wkclass.between(start_date, end_date))
     .where(workout_group_condition(workout_group_name))
     .order(:start_time)
  end

  private
    # https://api.rubyonrails.org/v6.1.4/classes/ActiveRecord/QueryMethods.html#method-i-where
    # If an array is passed, then the first element of the array is treated as a template, and the remaining elements are inserted into the template to generate the condition.
    def self.workout_group_condition(selection)
      ["workout_groups.name = ?", "#{selection}"] unless selection == 'All'
    end

end
