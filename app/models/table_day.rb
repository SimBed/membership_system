class TableDay < ApplicationRecord
  belongs_to :timetable
  has_many  :entries, dependent: :destroy
  before_save :upcase_names

    # https://www.rubyinrails.com/2021/12/14/fetch-records-in-custom-order-with-rails-activerecord/
    # use ruby to build the sql query order('CASE day WHEN 'Monday' then 0 WHEN 'Tuesday' then 1...END)
    # SORT_ORDER = Date::DAYNAMES.rotate(1).map(&:upcase)
    SORT_ORDER = Date::DAYNAMES.rotate(Date.today.cwday).map(&:upcase)
    scope :order_by_day, lambda {
        order_clause = 'CASE name '
        SORT_ORDER.each_with_index do |day, index|
          order_clause << sanitize_sql_array(['WHEN ? THEN ? ', day, index])
        end
        order_clause << sanitize_sql_array(['ELSE ? END', SORT_ORDER.length])
        order(Arel.sql(order_clause))
      }  

  private
    def upcase_names
      self.name = name.upcase
      self.short_name = short_name.upcase
    end      
end
