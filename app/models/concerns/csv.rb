module Csv
  extend ActiveSupport::Concern

  included do
    def self.to_csv
      CSV.generate(row_sep: "\n") do |csv|
        csv << column_names
        all.find_each do |client|
          csv << client.attributes.values_at(*column_names)
        end
      end
    end
  end
end
