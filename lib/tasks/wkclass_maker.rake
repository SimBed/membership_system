desc 'create wkclasses for the day based on timetable'
task wkclass_daily_create: :environment do
  wkclass_date = Time.zone.now.advance(days: 0) # settings
  day_of_week = wkclass_date.strftime('%A')
  entries=Entry.joins(table_day: [:timetable]).joins(:table_time).where('timetables.id=1').where(table_days: {name: day_of_week}).order('table_times.start')
  entries.each do |entry|
    start = entry.table_time.start
    wkclass = Wkclass.new(
      workout_id: 1, #entry.workout_id,
        start_time: wkclass_date.change({ hour: start.hour, min: start.min }),
        max_capacity: 12)
    wkclass.save(validate: false)
  end
end
