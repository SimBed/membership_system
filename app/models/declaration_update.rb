class DeclarationUpdate < ApplicationRecord
  belongs_to :declaration
  validates :date, presence: true
  validates :note, presence: true
  scope :order_by_submitted, -> { order(date: :desc) }
end