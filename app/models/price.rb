class Price < ApplicationRecord
  belongs_to :product
  validates :date_from, presence: true, allow_blank: false
  validates :name, presence: true
  validates :price, presence: true, numericality: { only_integer: true }
  scope :order_by_current_price, -> {order(current: :desc, price: :desc)}
  scope :current, -> {where(current: true).order(price: :desc)}
end
