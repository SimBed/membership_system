class Workout < ApplicationRecord
  has_many :rel_product_workouts, dependent: :destroy
  has_many :products, through: :rel_product_workouts
  belongs_to :instructor
  has_many :wkclasses
end
