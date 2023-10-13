# setup some current wkclasses to test booking system manually
days = [0 ,1, 2, 3]
group_times = [7, 9, 19]
opengym_times = [13, 14, 15]
instructor_id = Instructor.where(first_name: 'Apoorv').first.id
opengym_id = Workout.where(name: 'Open Gym').first.id
bootcamp_id = Workout.where(name: 'Bootcamp').first.id

days.each do |day|
  group_times.each do |group_time|
    Wkclass.create!(workout_id: bootcamp_id,
                    start_time: Time.zone.now.advance(days: day).change(hour: group_time, min: 00).strftime('%d/%m/%Y %H:%M'),
                    instructor_id: instructor_id,
                    instructor_rate_id: 2,
                    max_capacity: 12,
                    studio: 'cellar',
                    duration: 60)
  end
  opengym_times.each do |opengym_time|
    Wkclass.create!(workout_id: opengym_id,
                    start_time: Time.zone.now.advance(days: day).change(hour: opengym_time, min: 00).strftime('%d/%m/%Y %H:%M'),
                    instructor_id: instructor_id,
                    instructor_rate_id: 2,
                    max_capacity: 12,
                    studio: 'cellar',
                    duration: 60)
  end
end