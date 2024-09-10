class Announcement < ApplicationRecord
  validates :message, presence: true, length: {minimum: 10}
  has_many :notifications, dependent: :destroy
  has_many :accounts, through: :notifications
  has_many :clients, through: :accounts
  scope :order_by_created_at, -> { order(created_at: :desc)}
end