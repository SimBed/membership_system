namespace :db do
  desc 'Convert development DB to Rails test fixtures'
  task to_fixtures: :environment do
    # TABLES_TO_SKIP = %w[ar_internal_metadata schema_migrations].freeze
    tables_to_do = %w[purchases]

    begin
      ActiveRecord::Base.establish_connection
      ActiveRecord::Base.connection.tables.each do |table_name|
        # next if TABLES_TO_SKIP.include?(table_name)
        next unless tables_to_do.include?(table_name)

        i = '000'
        file_path = Rails.root.join("test/fixtures/#{table_name}.yml").to_s
        File.open(file_path, 'w') do |file|
          rows = ActiveRecord::Base.connection.select_all("SELECT * FROM #{table_name}")
          data = rows.each_with_object({}) do |record, hash|
            suffix = record['id'].presence || i.succ!
            hash["#{table_name.singularize}_#{suffix}"] = record
          end
          puts "Writing table '#{table_name}' to '#{file_path}'"
          file.write(data.to_yaml)
        end
      end
    ensure
      ActiveRecord::Base.connection&.close
    end
  end
end
