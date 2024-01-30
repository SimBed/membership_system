class StrengthMarker < ApplicationRecord
  belongs_to :client
  validates :date, presence: true
  validates :weight, presence: true, numericality: true  
  validates :reps, presence: true, numericality: true  
  validates :sets, presence: true, numericality: true

  scope :order_by_date, -> { order(date: :desc, name: :asc, weight: :asc) }
  scope :order_by_name, -> { order(name: :desc, date: :desc) }
  scope :order_by_weight, -> { order(weight: :desc, date: :desc) }
  # scope :with_client_id, ->(id) { joins(:client).where(client: {id: id})}
  scope :with_client_id, ->(id) { where(client_id: id)}
  scope :with_marker_name, ->(name) { where(name: name )}
end
