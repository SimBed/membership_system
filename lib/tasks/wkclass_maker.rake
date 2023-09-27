desc 'create wkclasses for the day based on timetable'
task wkclass_daily_create: :environment do
  wkclass_date = Time.zone.now.advance(days: Setting.classmaker_advance)
  day_of_week = wkclass_date.strftime('%A')
  entries = Entry.joins(table_day: [:timetable]).joins(:table_time).where(timetables: { id: Rails.application.config_for(:constants)['timetable_id'] }).where(table_days: { name: day_of_week }).order('table_times.start')
  entries.each do |entry|
    workout = Workout.find(entry.workout_id)
    start = entry.table_time.start
    max_capacity = workout.default_capacity
    if entry.studio == 'Window'
      max_capacity = [Rails.application.config_for(:constants)['window_capacity'], max_capacity].min
    end
    wkclass = Wkclass.new(
      workout_id: entry.workout_id,
      start_time: wkclass_date.change({ hour: start.hour, min: start.min }),
      max_capacity: max_capacity,
      level: entry.level,
      studio: entry.studio,
      duration: entry.duration,
      instructor_id: (Instructor.where(no_instructor: true)&.first.id if entry.workout.no_instructor?)
    )
    wkclass.save(validate: false)
  end
end
