class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  # http://www.freakular.co.uk/rails-except-scope/
  scope :exclude, -> (*values) { where("#{table_name}.id NOT IN (?)", values.compact.flatten.map { |e| e.is_a?(Integer) ? e : e.id } << 0 ) }  
  # scope :exclude, -> (*values) { 
  # where(
  #   "#{table_name}.id NOT IN (?)",
  #     (
  #       values.compact.flatten.map { |e|
  #         if e.is_a?(Integer) 
  #           e
  #         else
  #           e.is_a?(self) ? e.id : raise("Element not the same type as #{self}.")
  #         end
  #       } << 0
  #     )
  #   )
  # }  
end
