desc 'create wkclasses for the day based on timetable'
task wkclass_daily_create: :environment do
  wkclass_date = Time.zone.now.advance(days: Setting.classmaker_advance)
  day_of_week = wkclass_date.strftime('%A')
  entries = Entry.joins(table_day: [:timetable]).joins(:table_time).where(timetables: {id: Setting.timetable}).where(table_days: {name: day_of_week}).order('table_times.start')
  entries.each do |entry|
    start = entry.table_time.start
    max_capacity = entry.studio == 'Window' ? 8 : 12
    wkclass = Wkclass.new(
      workout_id: entry.workout_id,
      start_time: wkclass_date.change({ hour: start.hour, min: start.min }),
      max_capacity: max_capacity,
      level: entry.level
      )
    wkclass.save(validate: false)
  end
end
