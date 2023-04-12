class InstructorRate < ApplicationRecord
  has_many :wkclasses
  belongs_to :instructor
  scope :order_recent_first, -> { order(date_from: :desc) }
  scope :order_by_instructor, -> { joins(:instructor).order('first_name', 'date_from desc') }
  scope :order_by_current, -> { order(current: :desc) }
  scope :order_for_index, -> { joins(:instructor).order({current: :desc, group: :desc, first_name: :asc, rate: :asc}) }  
  scope :current, -> { where(current: true) }

  def long_name
    "#{group ? 'Group' : 'PT'} #{name}"
  end

end


