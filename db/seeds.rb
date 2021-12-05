# Clients
clients = [{:first_name => 'Aparna', :last_name => 'Shah'},
         {:first_name => 'Aryan', :last_name => 'Agarwal'},
         {:first_name => 'Bhavik', :last_name => 'Shah'},
         {:first_name => 'Ekta', :last_name => 'Sheth'},
         {:first_name => 'Falguni', :last_name => 'Trivedi'},
         {:first_name => 'Gautam', :last_name => 'Videographer'},
         {:first_name => 'Jugnu', :last_name => 'Shah'},
         {:first_name => 'Kajal', :last_name => 'Tiwari'},
         {:first_name => 'Malvika', :last_name => 'Saraf'},
         {:first_name => 'Nayantara', :last_name => 'Singh'},
         {:first_name => 'Rohan', :last_name => 'Mehta'},
         {:first_name => 'Shruti', :last_name => 'Bhandari'},
         {:first_name => 'Triveni', :last_name => 'Chouhan'},
         {:first_name => 'Varun', :last_name => 'Joshi'}]

clients.each do |c|
  Client.create!(first_name: c[:first_name], last_name: c[:last_name])
end

# Instructors
Instructor.create!(first_name: 'Apoorv', last_name: 'Mathur')

# Workouts
Workout.create!(name: 'HIIT', instructor_id: Instructor.where(first_name: 'Apoorv').first.id)

# Workout Groups
WorkoutGroup.create!(name: 'Space', workout_ids: [1])

# Products
# 1. Drop IN & Class Pass & Free
Product.create!(max_classes: 1, validity_length: 1, validity_unit: 'D', workout_group_id: 1)
# 2. 6C5W
Product.create!(max_classes: 6, validity_length: 5, validity_unit: 'W', workout_group_id: 1)
# 3. 8C5W
Product.create!(max_classes: 8, validity_length: 5, validity_unit: 'W', workout_group_id: 1)
# 4. U1M
Product.create!(max_classes: 1000, validity_length: 1, validity_unit: 'M', workout_group_id: 1)
# 5. U3M
Product.create!(max_classes: 1000, validity_length: 3, validity_unit: 'M', workout_group_id: 1)
# 6. U1W
Product.create!(max_classes: 1000, validity_length: 1, validity_unit: 'W', workout_group_id: 1)

# Classes
Wkclass.create!(workout_id:1, start_time: '8-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '9-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '10-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '11-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '12-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '15-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '16-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '17-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '18-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '19-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '22-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '23-11-2021 10:30')
Wkclass.create!(workout_id:1, start_time: '24-11-2021 10:30')

# Purchases to Nov 24
Purchase.create!(client_id: 1, product_id: 4, dop: '1-11-2021', payment: 7000)
Purchase.create!(client_id: 2, product_id: 6, dop: '1-11-2021', payment: 1000)
Purchase.create!(client_id: 3, product_id: 2, dop: '1-11-2021', payment: 3900)
Purchase.create!(client_id: 3, product_id: 5, dop: '11-11-2021', payment: 20000)
Purchase.create!(client_id: 4, product_id: 2, dop: '1-11-2021', payment: 3900)
Purchase.create!(client_id: 4, product_id: 5, dop: '11-11-2021', payment: 20000)
Purchase.create!(client_id: 5, product_id: 2, dop: '1-11-2021', payment: 3900)
Purchase.create!(client_id: 6, product_id: 1, dop: '1-11-2021', payment: 0)
Purchase.create!(client_id: 7, product_id: 1, dop: '1-11-2021', payment: 1000)
Purchase.create!(client_id: 8, product_id: 3, dop: '1-11-2021', payment: 5200)
Purchase.create!(client_id: 9, product_id: 1, dop: '1-11-2021', payment: 0)
Purchase.create!(client_id: 10, product_id: 1, dop: '1-11-2021', payment: 500)
Purchase.create!(client_id: 11, product_id: 4, dop: '1-11-2021', payment: 8000)
Purchase.create!(client_id: 12, product_id: 4, dop: '10-11-2021', payment: 7000)
Purchase.create!(client_id: 13, product_id: 2, dop: '1-11-2021', payment: 3900)
Purchase.create!(client_id: 13, product_id: 4, dop: '7-11-2021', payment: 7000)
Purchase.create!(client_id: 14, product_id: 6, dop: '1-11-2021', payment: 1000)

# Workout Groups
# todo

# rel_workout_group_workouts
# todo

# Attendances
Attendance.create!(wkclass_id: 1, purchase_id: 2)
Attendance.create!(wkclass_id: 1, purchase_id: 3)
Attendance.create!(wkclass_id: 1, purchase_id: 17)
Attendance.create!(wkclass_id: 2, purchase_id: 2)
Attendance.create!(wkclass_id: 2, purchase_id: 10)
Attendance.create!(wkclass_id: 2, purchase_id: 15)
Attendance.create!(wkclass_id: 3, purchase_id: 2)
Attendance.create!(wkclass_id: 3, purchase_id: 3)
Attendance.create!(wkclass_id: 3, purchase_id: 5)
Attendance.create!(wkclass_id: 3, purchase_id: 14)
