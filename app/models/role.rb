class Role < ApplicationRecord
  default_scope -> { order(:view_priority)}
end
