class BodyMarker < ApplicationRecord
  belongs_to :client
  validates :date, presence: true
  validates :measurement, presence: true, numericality: true  
  validates :bodypart, presence: true

  scope :order_by_date, -> { order(date: :desc, bodypart: :asc, measurement: :asc) }
  scope :order_by_bodypart, -> { order(bodypart: :desc, date: :desc) }
  scope :order_by_measurement, -> { order(measurement: :desc, date: :desc) }
  scope :with_client_id, ->(id) { joins(:client).where(client: {id: id})}
  scope :with_marker_bodypart, ->(bodypart) { where(bodypart: bodypart )}
end







