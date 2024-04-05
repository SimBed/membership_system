class InstructorRate < ApplicationRecord
  has_many :wkclasses, dependent: nil
  belongs_to :instructor
  validates :name, presence: true
  validates :rate, presence: true, numericality: true
  scope :order_recent_first, -> { order(date_from: :desc) }
  scope :order_by_instructor, -> { joins(:instructor).order('first_name', 'date_from desc') }
  scope :order_by_current, -> { order(current: :desc) }
  scope :order_by_group_instructor_rate, -> { joins(:instructor).order({ group: :desc, first_name: :asc, rate: :asc }) }
  scope :current, -> { where(current: true) }
  scope :not_current, -> { where.not(current: true) }

  def long_name
    "#{group ? 'Group' : 'PT'} #{name}"
  end

  def deletable?
    # return true if Wkclass.where(instructor_rate_id: id).empty?
    return true if Wkclass.has_instructor_rate(self).empty?

    false
  end  
end
