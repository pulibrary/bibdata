# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160224214320) do

  create_table "dump_file_types", force: :cascade do |t|
    t.string   "label",      limit: 255
    t.string   "constant",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "dump_file_types", ["constant"], name: "index_dump_file_types_on_constant", using: :btree

  create_table "dump_files", force: :cascade do |t|
    t.integer  "dump_id",           limit: 4
    t.string   "path",              limit: 255
    t.string   "md5",               limit: 255
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "dump_file_type_id", limit: 4
  end

  add_index "dump_files", ["dump_file_type_id"], name: "index_dump_files_on_dump_file_type_id", using: :btree
  add_index "dump_files", ["dump_id"], name: "index_dump_files_on_dump_id", using: :btree

  create_table "dump_types", force: :cascade do |t|
    t.string   "label",      limit: 255
    t.string   "constant",   limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "dump_types", ["constant"], name: "index_dump_types_on_constant", using: :btree

  create_table "dumps", force: :cascade do |t|
    t.integer  "event_id",     limit: 4
    t.integer  "dump_type_id", limit: 4
    t.text     "delete_ids",   limit: 4294967295
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.text     "update_ids",   limit: 4294967295
    t.text     "create_ids",   limit: 4294967295
  end

  add_index "dumps", ["dump_type_id"], name: "index_dumps_on_dump_type_id", using: :btree
  add_index "dumps", ["event_id"], name: "index_dumps_on_event_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "start"
    t.datetime "finish"
    t.text     "error",      limit: 65535
    t.boolean  "success"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "locations_delivery_locations", force: :cascade do |t|
    t.string   "label",                limit: 255
    t.text     "address",              limit: 65535
    t.string   "phone_number",         limit: 255
    t.string   "contact_email",        limit: 255
    t.boolean  "staff_only",                         default: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "locations_library_id", limit: 4
    t.string   "gfa_pickup",           limit: 255
    t.boolean  "pickup_location",                    default: false
    t.boolean  "digital_location"
  end

  add_index "locations_delivery_locations", ["locations_library_id"], name: "index_locations_delivery_locations_on_locations_library_id", using: :btree

  create_table "locations_holding_locations", force: :cascade do |t|
    t.string   "label",                              limit: 255
    t.string   "code",                               limit: 255
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.integer  "locations_library_id",               limit: 4
    t.boolean  "aeon_location",                                  default: false
    t.boolean  "recap_electronic_delivery_location",             default: false
    t.boolean  "open",                                           default: true
    t.boolean  "requestable",                                    default: true
    t.boolean  "always_requestable",                             default: false
    t.integer  "locations_hours_location_id",        limit: 4
    t.boolean  "circulates",                                     default: true
  end

  add_index "locations_holding_locations", ["locations_library_id"], name: "index_locations_holding_locations_on_locations_library_id", using: :btree

  create_table "locations_holdings_delivery", id: false, force: :cascade do |t|
    t.integer "locations_delivery_location_id", limit: 4
    t.integer "locations_holding_location_id",  limit: 4
  end

  add_index "locations_holdings_delivery", ["locations_delivery_location_id"], name: "index_lhd_on_ldl_id", using: :btree
  add_index "locations_holdings_delivery", ["locations_holding_location_id"], name: "index_ldl_on_lhd_id", using: :btree

  create_table "locations_hours_locations", force: :cascade do |t|
    t.string   "code",       limit: 255
    t.string   "label",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "locations_libraries", force: :cascade do |t|
    t.string   "label",      limit: 255
    t.string   "code",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "provider",               limit: 255
    t.string   "uid",                    limit: 255
    t.string   "username",               limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree

end
