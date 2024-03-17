class Role < ApplicationRecord
  has_many :assignments, dependent: :destroy
  default_scope -> { order(:view_priority) }
end
