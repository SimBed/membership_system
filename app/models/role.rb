class Role < ApplicationRecord
  has_many :assignments, dependent: :destroy
  # scope :employee_roles, -> { where.not(name: ['client']) }
  # scope :employee_roles_excl_superadmin, -> { where.not(name: ['client', 'superadmin']) }
  # Active Record already defined a class method named excluding
  scope :not_including, ->(*exclusions) { where.not(name: exclusions) }
  default_scope -> { order(:view_priority) }
end
