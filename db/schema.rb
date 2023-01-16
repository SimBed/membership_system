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

ActiveRecord::Schema.define(version: 2023_01_16_170619) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "email"
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "activated", default: false
    t.string "reset_digest"
    t.datetime "reset_sent_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "ac_type"
    t.index ["email"], name: "index_accounts_on_email", unique: true
  end

  create_table "adjustments", force: :cascade do |t|
    t.integer "purchase_id"
    t.integer "adjustment"
    t.text "note"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["purchase_id"], name: "index_adjustments_on_purchase_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.integer "wkclass_id"
    t.integer "purchase_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "status", default: "booked"
    t.string "booked_by"
    t.integer "amendment_count", default: 0
    t.boolean "amnesty", default: false
    t.index ["purchase_id"], name: "index_attendances_on_purchase_id"
    t.index ["status"], name: "index_attendances_on_status"
    t.index ["wkclass_id"], name: "index_attendances_on_wkclass_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "instagram"
    t.integer "account_id"
    t.text "note"
    t.string "whatsapp"
    t.boolean "hotlead", default: false
    t.boolean "fitternity", default: false
    t.boolean "waiver", default: false
    t.boolean "instawaiver", default: false
    t.index ["account_id"], name: "index_clients_on_account_id"
    t.index ["first_name", "last_name"], name: "index_clients_on_first_name_and_last_name"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "entries", force: :cascade do |t|
    t.string "goal"
    t.string "level"
    t.string "studio"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["amount"], name: "index_expenses_on_amount"
    t.index ["workout_group_id"], name: "index_expenses_on_workout_group_id"
  end

  create_table "fitternities", force: :cascade do |t|
    t.integer "max_classes"
    t.date "expiry_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "freezes", force: :cascade do |t|
    t.integer "purchase_id"
    t.date "start_date"
    t.date "end_date"
    t.text "note"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["purchase_id"], name: "index_freezes_on_purchase_id"
  end

  create_table "instructor_rates", force: :cascade do |t|
    t.integer "rate"
    t.date "date_from"
    t.bigint "instructor_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "current", default: true
    t.index ["instructor_id"], name: "index_instructor_rates_on_instructor_id"
  end

  create_table "instructors", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "current", default: true
  end

  create_table "orders", force: :cascade do |t|
    t.integer "product_id"
    t.integer "price"
    t.string "status"
    t.string "payment_id"
    t.integer "account_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "partners", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "account_id"
    t.string "email"
    t.string "phone"
    t.string "whatsapp"
    t.string "instagram"
    t.index ["account_id"], name: "index_partners_on_account_id"
  end

  create_table "penalties", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.bigint "attendance_id", null: false
    t.integer "amount"
    t.string "reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["attendance_id"], name: "index_penalties_on_attendance_id", unique: true
    t.index ["purchase_id"], name: "index_penalties_on_purchase_id"
  end

  create_table "prices", force: :cascade do |t|
    t.string "name"
    t.integer "price"
    t.date "date_from"
    t.boolean "current"
    t.integer "product_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "discount", default: 0.0
    t.boolean "base", default: false
    t.boolean "renewal_pre_expiry", default: false
    t.boolean "renewal_pretrial_expiry", default: false
    t.boolean "renewal_posttrial_expiry", default: false
    t.index ["base"], name: "index_prices_on_base"
    t.index ["product_id"], name: "index_prices_on_product_id"
    t.index ["renewal_posttrial_expiry"], name: "index_prices_on_renewal_posttrial_expiry"
    t.index ["renewal_pre_expiry"], name: "index_prices_on_renewal_pre_expiry"
    t.index ["renewal_pretrial_expiry"], name: "index_prices_on_renewal_pretrial_expiry"
  end

  create_table "products", force: :cascade do |t|
    t.integer "max_classes"
    t.integer "validity_length"
    t.string "validity_unit"
    t.integer "workout_group_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["max_classes"], name: "index_products_on_max_classes"
  end

  create_table "purchases", force: :cascade do |t|
    t.integer "client_id"
    t.integer "product_id"
    t.integer "payment"
    t.date "dop"
    t.string "payment_mode"
    t.string "invoice"
    t.text "note"
    t.boolean "adjust_restart", default: false
    t.integer "ar_payment"
    t.date "ar_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "fitternity_id"
    t.integer "price_id"
    t.string "status", default: "not started"
    t.date "expiry_date"
    t.date "start_date"
    t.boolean "tax_included", default: true
    t.integer "early_cancels", default: 0
    t.integer "late_cancels", default: 0
    t.integer "no_shows", default: 0
    t.index ["client_id"], name: "index_purchases_on_client_id"
    t.index ["dop"], name: "index_purchases_on_dop"
    t.index ["price_id"], name: "index_purchases_on_price_id"
    t.index ["product_id"], name: "index_purchases_on_product_id"
    t.index ["status"], name: "purchases_status_index"
  end

  create_table "rel_workout_group_workouts", force: :cascade do |t|
    t.integer "workout_group_id"
    t.integer "workout_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["workout_group_id"], name: "index_rel_workout_group_workouts_on_workout_group_id"
    t.index ["workout_id"], name: "index_rel_workout_group_workouts_on_workout_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "table_days", force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "timetable_id"
    t.index ["name"], name: "index_table_days_on_name"
    t.index ["timetable_id"], name: "index_table_days_on_timetable_id"
  end

  create_table "table_times", force: :cascade do |t|
    t.time "start"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "timetable_id"
    t.index ["start"], name: "index_table_times_on_start"
    t.index ["timetable_id"], name: "index_table_times_on_timetable_id"
  end

  create_table "timetables", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["title"], name: "index_timetables_on_title"
  end

  create_table "wkclasses", force: :cascade do |t|
    t.integer "workout_id"
    t.datetime "start_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "instructor_id"
    t.integer "instructor_cost"
    t.integer "max_capacity"
    t.string "level", default: "All Levels"
    t.index ["instructor_id"], name: "index_wkclasses_on_instructor_id"
    t.index ["start_time"], name: "index_wkclasses_on_start_time"
    t.index ["workout_id"], name: "index_wkclasses_on_workout_id"
  end

  create_table "workout_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "partner_id"
    t.integer "partner_share"
    t.boolean "gst_applies", default: true
    t.boolean "requires_invoice", default: true
    t.index ["name"], name: "index_workout_groups_on_name"
  end

  create_table "workouts", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "current", default: true
    t.boolean "instructor_initials", default: false
    t.index ["name"], name: "index_workouts_on_name"
  end

  add_foreign_key "entries", "workouts"
  add_foreign_key "expenses", "workout_groups"
  add_foreign_key "instructor_rates", "instructors"
  add_foreign_key "penalties", "attendances"
  add_foreign_key "penalties", "purchases"
end
