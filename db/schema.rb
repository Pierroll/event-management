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

ActiveRecord::Schema[8.1].define(version: 2026_06_23_052513) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.datetime "booked_at", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "expires_at"
    t.integer "quantity", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.bigint "ticket_type_id", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id", "status"], name: "index_bookings_on_event_and_status"
    t.index ["event_id"], name: "index_bookings_on_event_id"
    t.index ["ticket_type_id"], name: "index_bookings_on_ticket_type_id"
    t.index ["user_id", "event_id"], name: "index_bookings_on_user_and_event"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.integer "rating", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_comments_on_event_id"
    t.index ["user_id", "event_id"], name: "index_comments_on_user_id_and_event_id", unique: true
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "event_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "display_order", default: 0, null: false
    t.bigint "event_id", null: false
    t.string "image"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_event_images_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "address", null: false
    t.decimal "average_rating", precision: 3, scale: 2, default: "0.0", null: false
    t.bigint "category_id", null: false
    t.boolean "check_in_enabled", default: false, null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.string "currency", limit: 3, default: "PEN", null: false
    t.text "description", null: false
    t.datetime "end_date"
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.integer "max_capacity"
    t.string "name", null: false
    t.bigint "organizer_id", null: false
    t.datetime "start_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_events_on_category_id"
    t.index ["city"], name: "index_events_on_city"
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.index ["start_date"], name: "index_events_on_start_date"
    t.index ["status"], name: "index_events_on_status"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.string "provider", default: "mock", null: false
    t.string "provider_charge_id"
    t.jsonb "raw_response", default: {}
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["booking_id"], name: "index_payments_on_booking_id_unique", unique: true
    t.index ["provider_charge_id"], name: "index_payments_on_provider_charge_id", unique: true, where: "(provider_charge_id IS NOT NULL)"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "ticket_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.integer "max_per_order", default: 10
    t.string "name", null: false
    t.integer "position", default: 0
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "quantity_total", null: false
    t.datetime "sales_end_at"
    t.datetime "sales_start_at"
    t.datetime "updated_at", null: false
    t.index ["event_id", "name"], name: "index_ticket_types_on_event_id_and_name", unique: true
    t.index ["event_id"], name: "index_ticket_types_on_event_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "attendee_email"
    t.string "attendee_name"
    t.bigint "booking_id", null: false
    t.datetime "checked_in_at"
    t.datetime "created_at", null: false
    t.string "qr_code", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_tickets_on_booking_id"
    t.index ["qr_code"], name: "index_tickets_on_qr_code", unique: true
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "assigned_by_id"
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["assigned_by_id"], name: "index_user_roles_on_assigned_by_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "confirmation_attempts", default: 0
    t.string "confirmation_code"
    t.datetime "confirmation_sent_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookings", "events"
  add_foreign_key "bookings", "ticket_types"
  add_foreign_key "bookings", "users"
  add_foreign_key "comments", "events"
  add_foreign_key "comments", "users"
  add_foreign_key "event_images", "events"
  add_foreign_key "events", "categories"
  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "payments", "bookings"
  add_foreign_key "ticket_types", "events"
  add_foreign_key "tickets", "bookings"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_roles", "users", column: "assigned_by_id"
end
