module ParamsDateConstructor
  extend ActiveSupport::Concern
  included do
      def construct_date(hash)
        DateTime.new(hash['start_time(1i)'].to_i,
                    hash['start_time(2i)'].to_i,
                    hash['start_time(3i)'].to_i)
      end

      def deconstruct_date(date, n)
        advanced_date = date.advance(weeks: n)
        { 'start_time(1i)': advanced_date.year.to_s,
          'start_time(2i)': advanced_date.month.to_s,
          'start_time(3i)': advanced_date.day.to_s }
      end
    end
end
