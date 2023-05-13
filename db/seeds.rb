discount_reasons = [{"name"=>"None",
                    "rationale"=>"Base",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"Complimentary",
                    "rationale"=>"Discretion",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"Friends & Family",
                    "rationale"=>"Status",
                    "student"=>false,
                    "friends_and_family"=>true,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"New Year 2024",
                    "rationale"=>"Oneoff",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"Student",
                    "rationale"=>"Status",
                    "student"=>true,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"First Package",
                    "rationale"=>"Renewal",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>true,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"Renewal of Package Before Expiry",
                    "rationale"=>"Renewal",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>true,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"Renewal of Package After Expiry",
                    "rationale"=>"Renewal",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>true,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"Renewal of Trial Before Expiry",
                    "rationale"=>"Renewal",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>true,
                    "renewal_post_trial_expiry"=>false},
                  {"name"=>"Renewal of Trial After Expiry",
                    "rationale"=>"Renewal",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>true},
                  {"name"=>"Buddy",
                    "rationale"=>"Discretion",
                    "student"=>false,
                    "friends_and_family"=>false,
                    "first_package"=>false,
                    "renewal_pre_package_expiry"=>false,
                    "renewal_post_package_expiry"=>false,
                    "renewal_pre_trial_expiry"=>false,
                    "renewal_post_trial_expiry"=>false}]

discount_reasons.each do |d|
  DiscountReason.create!(name: d['name'], rationale: d['rationale'], student: d['student'], friends_and_family: d['friends_and_family'],
                         first_package: d['first_package'], renewal_pre_package_expiry: d['renewal_pre_package_expiry'], renewal_post_package_expiry: d['renewal_post_package_expiry'],
                         renewal_pre_trial_expiry: d['renewal_pre_trial_expiry'], renewal_post_trial_expiry: d['no_disrenewal_post_trial_expirycount'])
end                    

discounts = [{"discount_reason_id"=>1,
              "percent"=>0.0,
              "fixed"=>0,
              "group"=>true,
              "pt"=>true,
              "online"=>true,
              "start_date"=>"2023-05-04",
              "end_date"=>"2123-05-04"},
            {"discount_reason_id"=>2,
              "percent"=>100,
              "fixed"=>0,
              "group"=>true,
              "pt"=>true,
              "online"=>true,
              "start_date"=>"2023-05-04",
              "end_date"=>"2123-05-04"},
            {"discount_reason_id"=>3,
              "percent"=>25.0,
              "fixed"=>0,
              "group"=>true,
              "pt"=>true,
              "online"=>true,
              "start_date"=>"2023-05-04",
              "end_date"=>"2123-05-04"},
            {"discount_reason_id"=>5,
              "percent"=>40.0,
              "fixed"=>0,
              "group"=>true,
              "pt"=>false,
              "online"=>false,
              "start_date"=>"2023-05-04",
              "end_date"=>"2123-05-04"},
            {"discount_reason_id"=>6,
              "percent"=>100.0,
              "fixed"=>0,
              "group"=>true,
              "pt"=>true,
              "online"=>true,
              "start_date"=>"2023-05-04",
              "end_date"=>"2123-05-08"},
            {"discount_reason_id"=>6,
              "percent"=>10.0,
              "fixed"=>0,
              "group"=>true,
              "pt"=>true,
              "online"=>true,
              "start_date"=>"2023-05-04",
              "end_date"=>"2123-05-10"},
            {"discount_reason_id"=>9,
              "percent"=>15.0,
              "fixed"=>0,
              "group"=>true,
              "pt"=>false,
              "online"=>false,
              "start_date"=>"2023-05-03",
              "end_date"=>"2123-05-04"},
            {"discount_reason_id"=>7,
              "percent"=>10.0,
              "fixed"=>0,
              "group"=>true,
              "pt"=>false,
              "online"=>false,
              "start_date"=>"2023-05-04",
              "end_date"=>"2123-05-04"},
            {"discount_reason_id"=>9,
              "percent"=>15.0,
              "fixed"=>0,
              "group"=>true,
              "pt"=>false,
              "online"=>false,
              "start_date"=>"2023-05-04",
              "end_date"=>"2123-05-04"},
            {"discount_reason_id"=>4,
            "percent"=>0.0,
            "fixed"=>1000,
            "group"=>true,
            "pt"=>false,
            "online"=>false,
            "start_date"=>"2024-01-01",
            "end_date"=>"2024-01-31"}]
discounts.each do |d|
  Discount.create!(discount_reason_id: d['discount_reason_id'], percent: d['percent'].to_i, fixed: d['fixed'].to_i, group: d['group'],
                   pt: d['pt'], online: d['online'], start_date: Date.parse(d['start_date']), end_date: Date.parse(d['end_date']))
end



# # Clients
# clients = [{:first_name => 'Aparna', :last_name => 'Shah'},
#          {:first_name => 'Aryan', :last_name => 'Agarwal'},
#          {:first_name => 'Bhavik', :last_name => 'Shah'},
#          {:first_name => 'Ekta', :last_name => 'Sheth'},
#          {:first_name => 'Falguni', :last_name => 'Trivedi'},
#          {:first_name => 'Gautam', :last_name => 'Videographer'},
#          {:first_name => 'Jugnu', :last_name => 'Shah'},
#          {:first_name => 'Kajal', :last_name => 'Tiwari'},
#          {:first_name => 'Malvika', :last_name => 'Saraf'},
#          {:first_name => 'Nayantara', :last_name => 'Singh'},
#          {:first_name => 'Rohan', :last_name => 'Mehta'},
#          {:first_name => 'Shruti', :last_name => 'Bhandari'},
#          {:first_name => 'Triveni', :last_name => 'Chouhan'},
#          {:first_name => 'Varun', :last_name => 'Joshi'}]

# clients.each do |c|
#   Client.create!(first_name: c[:first_name], last_name: c[:last_name])
# end

# # Instructors
# Instructor.create!(first_name: 'Ap', last_name: 'Mat')
# Instructor.create!(first_name: 'Amit', last_name: 'Sir')
# Instructor.create!(first_name: 'Kar', last_name: 'Ram')
# Instructor.create!(first_name: 'Raki', last_name: 'G')

# # Partners
# Partner.create!(first_name: 'Ap', last_name: 'Mat')
# Partner.create!(first_name: 'Kar', last_name: 'Ram')

# # Workouts
# Workout.create!(name: 'HIIT')
# Workout.create!(name: 'S&C')
# Workout.create!(name: 'PSM')
# Workout.create!(name: 'Mat Pilates')

# # Workout Groups
# WorkoutGroup.create!(name: 'Space', workout_ids: [1, 2, 4], partner_id: Partner.where(first_name: 'Ap').first.id)
# WorkoutGroup.create!(name: 'Pilates', workout_ids: [3, 4], partner_id: Partner.where(first_name: 'Kar').first.id)

# # Products
# # 1. Drop IN & Class Pass & Free
# Product.create!(max_classes: 1, validity_length: 1, validity_unit: 'D', workout_group_id: 1)
# # 2. 6C5W
# Product.create!(max_classes: 6, validity_length: 5, validity_unit: 'W', workout_group_id: 1)
# # 3. 8C5W
# Product.create!(max_classes: 8, validity_length: 5, validity_unit: 'W', workout_group_id: 1)
# # 4. U1M
# Product.create!(max_classes: 1000, validity_length: 1, validity_unit: 'M', workout_group_id: 1)
# # 5. U3M
# Product.create!(max_classes: 1000, validity_length: 3, validity_unit: 'M', workout_group_id: 1)
# # 6. U1W
# Product.create!(max_classes: 1000, validity_length: 1, validity_unit: 'W', workout_group_id: 1)

# # Classes
# instructorid = Instructor.where(first_name: 'Raki').first.id
# Wkclass.create!(workout_id:1, start_time: '21-09-2021 10:30', instructor_id: instructorid) #1
# Wkclass.create!(workout_id:1, start_time: '05-10-2021 10:30', instructor_id: instructorid) #2
# Wkclass.create!(workout_id:1, start_time: '07-10-2021 10:30', instructor_id: instructorid) #3
# Wkclass.create!(workout_id:1, start_time: '12-10-2021 10:30', instructor_id: instructorid) #4
# Wkclass.create!(workout_id:1, start_time: '21-10-2021 10:30', instructor_id: instructorid) #5
# Wkclass.create!(workout_id:1, start_time: '26-10-2021 10:30', instructor_id: instructorid) #6
# Wkclass.create!(workout_id:1, start_time: '28-10-2021 10:30', instructor_id: instructorid) #7
# Wkclass.create!(workout_id:1, start_time: '30-10-2021 10:30', instructor_id: instructorid) #8
# Wkclass.create!(workout_id:1, start_time: '8-11-2021 10:30', instructor_id: instructorid) #9
# Wkclass.create!(workout_id:1, start_time: '9-11-2021 10:30', instructor_id: instructorid) #10
# Wkclass.create!(workout_id:1, start_time: '10-11-2021 10:30', instructor_id: instructorid) #11
# Wkclass.create!(workout_id:1, start_time: '11-11-2021 10:30', instructor_id: instructorid) #12
# Wkclass.create!(workout_id:1, start_time: '12-11-2021 10:30', instructor_id: instructorid) #13
# Wkclass.create!(workout_id:1, start_time: '13-11-2021 10:30', instructor_id: instructorid) #14
# Wkclass.create!(workout_id:1, start_time: '15-11-2021 10:30', instructor_id: instructorid) #15
# Wkclass.create!(workout_id:1, start_time: '16-11-2021 10:30', instructor_id: instructorid) #16
# Wkclass.create!(workout_id:1, start_time: '17-11-2021 10:30', instructor_id: instructorid) #17
# Wkclass.create!(workout_id:1, start_time: '18-11-2021 10:30', instructor_id: instructorid) #18
# Wkclass.create!(workout_id:1, start_time: '19-11-2021 10:30', instructor_id: instructorid) #19
# Wkclass.create!(workout_id:1, start_time: '20-11-2021 10:30', instructor_id: instructorid) #20
# Wkclass.create!(workout_id:1, start_time: '22-11-2021 10:30', instructor_id: instructorid) #21
# Wkclass.create!(workout_id:1, start_time: '23-11-2021 10:30', instructor_id: instructorid) #22
# Wkclass.create!(workout_id:1, start_time: '24-11-2021 10:30', instructor_id: instructorid) #23


# Purchase.create!(client_id: 1, product_id: 4, dop: '13-11-2021', payment: 7000, payment_mode: 'cash')
# Purchase.create!(client_id: 2, product_id: 6, dop: '06-11-2021', payment: 1000, payment_mode: 'cash')
# Purchase.create!(client_id: 3, product_id: 2, dop: '05-10-2021', payment: 3900, payment_mode: 'cash')
# Purchase.create!(client_id: 3, product_id: 5, dop: '09-11-2021', payment: 20000, payment_mode: 'cash')
# Purchase.create!(client_id: 4, product_id: 2, dop: '13-10-2021', payment: 3900, payment_mode: 'cash')
# Purchase.create!(client_id: 4, product_id: 5, dop: '11-11-2021', payment: 20000, payment_mode: 'cash')
# Purchase.create!(client_id: 5, product_id: 2, dop: '17-09-2021', payment: 3900, payment_mode: 'cash')
# Purchase.create!(client_id: 6, product_id: 1, dop: '13-11-2021', payment: 0, payment_mode: 'cash')
# Purchase.create!(client_id: 7, product_id: 1, dop: '16-11-2021', payment: 1000, payment_mode: 'cash')
# Purchase.create!(client_id: 8, product_id: 3, dop: '7-10-2021', payment: 5200, payment_mode: 'cash')
# Purchase.create!(client_id: 9, product_id: 1, dop: '13-11-2021', payment: 0, payment_mode: 'cash')
# Purchase.create!(client_id: 10, product_id: 1, dop: '18-11-2021', payment: 500, payment_mode: 'cash')
# Purchase.create!(client_id: 11, product_id: 4, dop: '23-11-2021', payment: 8000, payment_mode: 'cash') #Rohan
# Purchase.create!(client_id: 12, product_id: 4, dop: '10-11-2021', payment: 7000, payment_mode: 'cash') #Shruti
# Purchase.create!(client_id: 13, product_id: 2, dop: '26-10-2021', payment: 3900, payment_mode: 'cash') #Triveni
# Purchase.create!(client_id: 13, product_id: 4, dop: '7-11-2021', payment: 7000, payment_mode: 'cash') #Triveni
# Purchase.create!(client_id: 14, product_id: 6, dop: '8-11-2021', payment: 1000, payment_mode: 'cash') #Varun

# # Attendances
# [14, 15, 16, 18, 19, 20, 23].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 1) }
# [9, 10, 11, 13].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 2) }
# [2, 5, 7, 8, 9, 11].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 3) }
# [12, 15, 16, 17, 18, 20, 21].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 4) }
# [4, 5, 6, 7, 8, 11].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 5) }
# [12, 16, 17, 18, 20, 23].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 6) }
# [1].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 7) }
# [16].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 9) }
# [3, 4, 10, 12].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 10) }
# [14].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 11) }
# [18].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 12) }
# [22, 23].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 13) } #Rohan
# [11, 12, 14, 19, 21].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 14) } #Shruti
# [6, 10, 12, 14, 16, 18].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 15) } #Triveni
# [19, 20, 21, 23].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 16) } #Triveni
# [9].each { |a| Attendance.create!(wkclass_id: a, purchase_id: 17) } #Varun
