# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_16_154354) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campus_accesses", force: :cascade do |t|
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_campus_accesses_on_uid"
  end

  create_table "dump_file_types", id: :serial, force: :cascade do |t|
    t.string "label"
    t.string "constant"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["constant"], name: "index_dump_file_types_on_constant"
  end

  create_table "dump_files", id: :serial, force: :cascade do |t|
    t.integer "dump_id"
    t.string "path"
    t.string "md5"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dump_file_type_id"
    t.index ["dump_file_type_id"], name: "index_dump_files_on_dump_file_type_id"
    t.index ["dump_id"], name: "index_dump_files_on_dump_id"
  end

  create_table "dump_types", id: :serial, force: :cascade do |t|
    t.string "label"
    t.string "constant"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["constant"], name: "index_dump_types_on_constant"
  end

  create_table "dumps", id: :serial, force: :cascade do |t|
    t.integer "event_id"
    t.integer "dump_type_id"
    t.text "delete_ids"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "update_ids"
    t.text "create_ids"
    t.index ["dump_type_id"], name: "index_dumps_on_dump_type_id"
    t.index ["event_id"], name: "index_dumps_on_event_id"
  end

  create_table "events", id: :serial, force: :cascade do |t|
    t.datetime "start"
    t.datetime "finish"
    t.text "error"
    t.boolean "success"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", id: :serial, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "hathi_accesses", force: :cascade do |t|
    t.string "oclc_number"
    t.string "bibid"
    t.string "status"
    t.string "origin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["oclc_number"], name: "index_hathi_accesses_on_oclc_number"
    t.index ["origin"], name: "index_hathi_accesses_on_origin"
    t.index ["status"], name: "index_hathi_accesses_on_status"
  end

  create_table "locations_delivery_locations", id: :serial, force: :cascade do |t|
    t.string "label"
    t.text "address"
    t.string "phone_number"
    t.string "contact_email"
    t.boolean "staff_only", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "locations_library_id"
    t.string "gfa_pickup"
    t.boolean "pickup_location", default: false
    t.boolean "digital_location"
    t.index ["locations_library_id"], name: "index_locations_delivery_locations_on_locations_library_id"
  end

  create_table "locations_floors", id: :serial, force: :cascade do |t|
    t.string "label"
    t.string "floor_plan_image"
    t.string "starting_point"
    t.string "walkable_areas"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "locations_library_id"
    t.index ["locations_library_id"], name: "index_locations_floors_on_locations_library_id"
  end

  create_table "locations_holding_locations", id: :serial, force: :cascade do |t|
    t.string "label"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "locations_library_id"
    t.boolean "aeon_location", default: false
    t.boolean "recap_electronic_delivery_location", default: false
    t.boolean "open", default: true
    t.boolean "requestable", default: true
    t.boolean "always_requestable", default: false
    t.integer "locations_hours_location_id"
    t.boolean "circulates", default: true
    t.integer "holding_library_id"
    t.index ["locations_library_id"], name: "index_locations_holding_locations_on_locations_library_id"
  end

  create_table "locations_holdings_delivery", id: false, force: :cascade do |t|
    t.integer "locations_delivery_location_id"
    t.integer "locations_holding_location_id"
    t.index ["locations_delivery_location_id"], name: "index_lhd_on_ldl_id"
    t.index ["locations_holding_location_id"], name: "index_ldl_on_lhd_id"
  end

  create_table "locations_hours_locations", id: :serial, force: :cascade do |t|
    t.string "code"
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "locations_libraries", id: :serial, force: :cascade do |t|
    t.string "label"
    t.string "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order", default: 0
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "locations_delivery_locations", "locations_libraries"
  add_foreign_key "locations_floors", "locations_libraries"
  add_foreign_key "locations_holding_locations", "locations_hours_locations"
  add_foreign_key "locations_holding_locations", "locations_libraries"
  add_foreign_key "locations_holding_locations", "locations_libraries", column: "holding_library_id"
end
