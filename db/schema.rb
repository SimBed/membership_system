# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_02_20_042018) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "activated", default: false
    t.string "reset_digest"
    t.datetime "reset_sent_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ac_type"
    t.index ["email"], name: "index_accounts_on_email", unique: true
  end

  create_table "achievements", force: :cascade do |t|
    t.date "date"
    t.integer "score"
    t.bigint "challenge_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_achievements_on_challenge_id"
    t.index ["client_id"], name: "index_achievements_on_client_id"
    t.index ["date"], name: "index_achievements_on_date"
    t.index ["score"], name: "index_achievements_on_score"
  end

  create_table "adjustments", force: :cascade do |t|
    t.integer "purchase_id"
    t.integer "adjustment"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_id"], name: "index_adjustments_on_purchase_id"
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_assignments_on_account_id"
    t.index ["role_id"], name: "index_assignments_on_role_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.integer "wkclass_id"
    t.integer "purchase_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "booked"
    t.string "booked_by"
    t.integer "amendment_count", default: 0
    t.boolean "amnesty", default: false
    t.index ["purchase_id"], name: "index_attendances_on_purchase_id"
    t.index ["status"], name: "index_attendances_on_status"
    t.index ["wkclass_id"], name: "index_attendances_on_wkclass_id"
  end

  create_table "body_markers", force: :cascade do |t|
    t.string "bodypart"
    t.float "measurement"
    t.date "date"
    t.text "note"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bodypart"], name: "index_body_markers_on_bodypart"
    t.index ["client_id"], name: "index_body_markers_on_client_id"
    t.index ["date"], name: "index_body_markers_on_date"
    t.index ["measurement"], name: "index_body_markers_on_measurement"
  end

  create_table "challenges", force: :cascade do |t|
    t.string "name"
    t.string "metric"
    t.string "metric_type"
    t.bigint "challenge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["challenge_id"], name: "index_challenges_on_challenge_id"
    t.index ["name"], name: "index_challenges_on_name"
  end

  create_table "clients", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "instagram"
    t.integer "account_id"
    t.text "note"
    t.string "whatsapp"
    t.boolean "hotlead", default: false
    t.boolean "fitternity", default: false
    t.boolean "waiver", default: false
    t.boolean "instawaiver", default: false
    t.boolean "whatsapp_group", default: false
    t.boolean "student", default: false
    t.boolean "friends_and_family", default: false
    t.index ["account_id"], name: "index_clients_on_account_id"
    t.index ["first_name", "last_name"], name: "index_clients_on_first_name_and_last_name"
    t.index ["friends_and_family"], name: "index_clients_on_friends_and_family"
    t.index ["student"], name: "index_clients_on_student"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "discount_assignments", force: :cascade do |t|
    t.bigint "discount_id", null: false
    t.bigint "purchase_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discount_id"], name: "index_discount_assignments_on_discount_id"
    t.index ["purchase_id"], name: "index_discount_assignments_on_purchase_id"
  end

  create_table "discount_reasons", force: :cascade do |t|
    t.string "name"
    t.string "rationale"
    t.boolean "student", default: false
    t.boolean "friends_and_family", default: false
    t.boolean "first_package", default: false
    t.boolean "renewal_pre_package_expiry", default: false
    t.boolean "renewal_post_package_expiry", default: false
    t.boolean "renewal_pre_trial_expiry", default: false
    t.boolean "renewal_post_trial_expiry", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "current", default: true
    t.index ["current"], name: "index_discount_reasons_on_current"
    t.index ["first_package"], name: "index_discount_reasons_on_first_package"
    t.index ["friends_and_family"], name: "index_discount_reasons_on_friends_and_family"
    t.index ["name"], name: "index_discount_reasons_on_name"
    t.index ["rationale"], name: "index_discount_reasons_on_rationale"
    t.index ["renewal_post_package_expiry"], name: "index_discount_reasons_on_renewal_post_package_expiry"
    t.index ["renewal_post_trial_expiry"], name: "index_discount_reasons_on_renewal_post_trial_expiry"
    t.index ["renewal_pre_package_expiry"], name: "index_discount_reasons_on_renewal_pre_package_expiry"
    t.index ["renewal_pre_trial_expiry"], name: "index_discount_reasons_on_renewal_pre_trial_expiry"
    t.index ["student"], name: "index_discount_reasons_on_student"
  end

  create_table "discounts", force: :cascade do |t|
    t.bigint "discount_reason_id", null: false
    t.float "percent"
    t.integer "fixed"
    t.boolean "group", default: true
    t.boolean "pt", default: false
    t.boolean "online", default: false
    t.boolean "aggregatable", default: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discount_reason_id"], name: "index_discounts_on_discount_reason_id"
    t.index ["end_date"], name: "index_discounts_on_end_date"
    t.index ["group"], name: "index_discounts_on_group"
    t.index ["online"], name: "index_discounts_on_online"
    t.index ["pt"], name: "index_discounts_on_pt"
    t.index ["start_date"], name: "index_discounts_on_start_date"
  end

  create_table "entries", force: :cascade do |t|
    t.string "goal"
    t.string "level"
    t.string "studio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "table_time_id"
    t.bigint "table_day_id"
    t.integer "duration", default: 60
    t.bigint "workout_id", default: 1, null: false
    t.index ["table_day_id"], name: "index_entries_on_table_day_id"
    t.index ["table_time_id"], name: "index_entries_on_table_time_id"
    t.index ["workout_id"], name: "index_entries_on_workout_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.string "item"
    t.integer "amount"
    t.date "date"
    t.bigint "workout_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["amount"], name: "index_expenses_on_amount"
    t.index ["workout_group_id"], name: "index_expenses_on_workout_group_id"
  end

  create_table "fitternities", force: :cascade do |t|
    t.integer "max_classes"
    t.date "expiry_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "freezes", force: :cascade do |t|
    t.integer "purchase_id"
    t.date "start_date"
    t.date "end_date"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "medical", default: false
    t.boolean "doctor_note", default: false
    t.string "added_by"
    t.index ["doctor_note"], name: "index_freezes_on_doctor_note"
    t.index ["medical"], name: "index_freezes_on_medical"
    t.index ["purchase_id"], name: "index_freezes_on_purchase_id"
  end

  create_table "instructor_rates", force: :cascade do |t|
    t.integer "rate"
    t.date "date_from"
    t.bigint "instructor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "current", default: true
    t.boolean "group"
    t.string "name"
    t.index ["group"], name: "index_instructor_rates_on_group"
    t.index ["instructor_id"], name: "index_instructor_rates_on_instructor_id"
    t.index ["name"], name: "index_instructor_rates_on_name"
  end

  create_table "instructors", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "current", default: true
    t.string "email"
    t.string "whatsapp"
    t.bigint "account_id"
    t.boolean "no_instructor", default: false
    t.boolean "commission", default: false
    t.boolean "employee", default: true
    t.index ["account_id"], name: "index_instructors_on_account_id"
    t.index ["no_instructor"], name: "index_instructors_on_no_instructor"
  end

  create_table "orders", force: :cascade do |t|
    t.integer "product_id"
    t.integer "price"
    t.string "status"
    t.string "payment_id"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "client_ui"
    t.index ["client_ui"], name: "index_orders_on_client_ui"
  end

  create_table "other_services", force: :cascade do |t|
    t.string "name"
    t.string "link"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_other_services_on_name"
  end

  create_table "partners", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "email"
    t.string "phone"
    t.string "whatsapp"
    t.string "instagram"
    t.index ["account_id"], name: "index_partners_on_account_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount"
    t.date "dop"
    t.string "payment_mode"
    t.boolean "online"
    t.string "invoice"
    t.text "note"
    t.integer "payable_id"
    t.string "payable_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dop"], name: "index_payments_on_dop"
    t.index ["online"], name: "index_payments_on_online"
    t.index ["payable_id", "payable_type"], name: "index_payments_on_payable_id_and_payable_type"
    t.index ["payment_mode"], name: "index_payments_on_payment_mode"
  end

  create_table "penalties", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.bigint "attendance_id", null: false
    t.integer "amount"
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_id"], name: "index_penalties_on_attendance_id", unique: true
    t.index ["purchase_id"], name: "index_penalties_on_purchase_id"
  end

  create_table "prices", force: :cascade do |t|
    t.integer "price"
    t.date "date_from"
    t.integer "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date_until"
    t.index ["date_from"], name: "index_prices_on_date_from"
    t.index ["date_until"], name: "index_prices_on_date_until"
    t.index ["product_id"], name: "index_prices_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.integer "max_classes"
    t.integer "validity_length"
    t.string "validity_unit"
    t.integer "workout_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "sellonline", default: false
    t.boolean "current", default: true
    t.string "color"
    t.boolean "rider", default: false
    t.boolean "has_rider", default: false
    t.index ["color"], name: "index_products_on_color"
    t.index ["current"], name: "index_products_on_current"
    t.index ["max_classes"], name: "index_products_on_max_classes"
    t.index ["rider"], name: "index_products_on_rider"
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "client_id"
    t.integer "product_id"
    t.integer "payment"
    t.date "dop"
    t.string "payment_mode"
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fitternity_id"
    t.integer "price_id"
    t.string "status", default: "not started"
    t.date "expiry_date"
    t.date "start_date"
    t.boolean "tax_included", default: true
    t.integer "early_cancels", default: 0
    t.integer "late_cancels", default: 0
    t.integer "no_shows", default: 0
    t.date "sunset_date"
    t.bigint "purchase_id"
    t.index ["client_id"], name: "index_purchases_on_client_id"
    t.index ["dop"], name: "index_purchases_on_dop"
    t.index ["price_id"], name: "index_purchases_on_price_id"
    t.index ["product_id"], name: "index_purchases_on_product_id"
    t.index ["purchase_id"], name: "index_purchases_on_purchase_id"
    t.index ["status"], name: "purchases_status_index"
  end

  create_table "regular_expenses", force: :cascade do |t|
    t.string "item"
    t.integer "amount"
    t.bigint "workout_group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_group_id"], name: "index_regular_expenses_on_workout_group_id"
  end

  create_table "rel_workout_group_workouts", force: :cascade do |t|
    t.integer "workout_group_id"
    t.integer "workout_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_group_id"], name: "index_rel_workout_group_workouts_on_workout_group_id"
    t.index ["workout_id"], name: "index_rel_workout_group_workouts_on_workout_id"
  end

  create_table "restarts", force: :cascade do |t|
    t.text "note"
    t.string "added_by"
    t.bigint "parent_id"
    t.bigint "child_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_restarts_on_child_id"
    t.index ["parent_id"], name: "index_restarts_on_parent_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.integer "view_priority"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "strength_markers", force: :cascade do |t|
    t.string "name"
    t.float "weight"
    t.integer "reps"
    t.integer "sets"
    t.date "date"
    t.text "note"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_strength_markers_on_client_id"
    t.index ["date"], name: "index_strength_markers_on_date"
    t.index ["name"], name: "index_strength_markers_on_name"
  end

  create_table "table_days", force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "timetable_id"
    t.index ["name"], name: "index_table_days_on_name"
    t.index ["timetable_id"], name: "index_table_days_on_timetable_id"
  end

  create_table "table_times", force: :cascade do |t|
    t.time "start"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "timetable_id"
    t.index ["start"], name: "index_table_times_on_start"
    t.index ["timetable_id"], name: "index_table_times_on_timetable_id"
  end

  create_table "timetables", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title"], name: "index_timetables_on_title"
  end

  create_table "waitings", force: :cascade do |t|
    t.bigint "wkclass_id", null: false
    t.bigint "purchase_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_id"], name: "index_waitings_on_purchase_id"
    t.index ["wkclass_id"], name: "index_waitings_on_wkclass_id"
  end

  create_table "wkclasses", force: :cascade do |t|
    t.integer "workout_id"
    t.datetime "start_time", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "instructor_id"
    t.integer "instructor_cost"
    t.integer "max_capacity"
    t.string "level", default: "All Levels"
    t.integer "instructor_rate_id"
    t.string "studio"
    t.integer "duration"
    t.index ["instructor_id"], name: "index_wkclasses_on_instructor_id"
    t.index ["start_time"], name: "index_wkclasses_on_start_time"
    t.index ["workout_id"], name: "index_wkclasses_on_workout_id"
  end

  create_table "workout_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "partner_id"
    t.integer "partner_share"
    t.boolean "gst_applies", default: true
    t.boolean "requires_invoice", default: true
    t.boolean "renewable", default: false
    t.boolean "requires_account", default: false
    t.string "service"
    t.index ["name"], name: "index_workout_groups_on_name"
    t.index ["service"], name: "index_workout_groups_on_service"
  end

  create_table "workouts", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "current", default: true
    t.boolean "instructor_initials", default: false
    t.boolean "no_instructor", default: false
    t.boolean "limited", default: true
    t.integer "default_capacity", default: 12
    t.index ["name"], name: "index_workouts_on_name"
  end

  add_foreign_key "achievements", "challenges"
  add_foreign_key "achievements", "clients"
  add_foreign_key "assignments", "accounts"
  add_foreign_key "assignments", "roles"
  add_foreign_key "body_markers", "clients"
  add_foreign_key "challenges", "challenges"
  add_foreign_key "discount_assignments", "discounts"
  add_foreign_key "discount_assignments", "purchases"
  add_foreign_key "discounts", "discount_reasons"
  add_foreign_key "entries", "workouts"
  add_foreign_key "expenses", "workout_groups"
  add_foreign_key "instructor_rates", "instructors"
  add_foreign_key "instructors", "accounts"
  add_foreign_key "penalties", "attendances"
  add_foreign_key "penalties", "purchases"
  add_foreign_key "purchases", "purchases"
  add_foreign_key "regular_expenses", "workout_groups"
  add_foreign_key "restarts", "purchases", column: "child_id"
  add_foreign_key "restarts", "purchases", column: "parent_id"
  add_foreign_key "strength_markers", "clients"
  add_foreign_key "waitings", "purchases"
  add_foreign_key "waitings", "wkclasses"
end
