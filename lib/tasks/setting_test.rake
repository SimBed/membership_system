desc 'write a setting to output'
task output_setting: :environment do
  puts Setting.cold
end
