class TableDay < ApplicationRecord
  belongs_to :timetable
  has_many :entries, dependent: :destroy
  before_save :upcase_names
  validate :no_repeated_days
  # Rails 7 introduces ActiveRecord::QueryMethods#in_order_of making previous SQL approach reundant
  # https://www.rubyinrails.com/2021/12/14/fetch-records-in-custom-order-with-rails-activerecord/
  SORT_ORDER = Date::DAYNAMES.rotate(Time.zone.today.cwday) #timetable's first column is today's day
  # SORT_ORDER = Date::DAYNAMES.rotate(1) #timetable's first column is Monday
  scope :order_by_day, -> { in_order_of(:name, SORT_ORDER) }

  private

  def self.for_day_of_week(timetable, day_of_week)
    # note this can't be a scope as we want to return a single object not a chainable AcctiveRecord relation
    # https://stackoverflow.com/questions/13070658/first-or-limit-in-rails-scope
    where(timetable_id: timetable.id, name: day_of_week).first
  end
  
  def upcase_names
    self.short_name = short_name.upcase
  end


  def no_repeated_days
    return if TableDay.for_day_of_week(timetable, name).nil?

    errors.add(:base, "The timetable already has a day with that name")
  end
end
    
# use ruby to build the sql query order('CASE day WHEN 'Monday' then 0 WHEN 'Tuesday' then 1...END)
# scope :order_by_day, lambda {
#                        order_clause = 'CASE name '
#                        SORT_ORDER.each_with_index do |day, index|
#                          order_clause << sanitize_sql_array(['WHEN ? THEN ? ', day, index])
#                        end
#                        order_clause << sanitize_sql_array(['ELSE ? END', SORT_ORDER.length])
#                        order(Arel.sql(order_clause))
#                      }