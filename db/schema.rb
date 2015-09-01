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

ActiveRecord::Schema.define(version: 20150901162835) do

  create_table "item_images", force: :cascade do |t|
    t.string   "image",      limit: 255
    t.integer  "item_id",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "item_lists", force: :cascade do |t|
    t.integer  "item_id",    limit: 4, null: false
    t.integer  "list_id",    limit: 4, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "items", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.text     "description",    limit: 65535
    t.boolean  "is_list",        limit: 1,     default: false, null: false
    t.boolean  "is_garbage",     limit: 1,     default: false, null: false
    t.boolean  "is_private",     limit: 1,     default: false, null: false
    t.integer  "count",          limit: 4,     default: 1,     null: false
    t.text     "garbage_reason", limit: 65535
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "user_id",        limit: 4,                     null: false
  end

  create_table "social_profiles", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.string   "provider",     limit: 30
    t.string   "uid",          limit: 160
    t.string   "access_token", limit: 255
    t.string   "token_secret", limit: 255
    t.string   "name",         limit: 255
    t.string   "nickname",     limit: 255
    t.string   "email",        limit: 255
    t.string   "url",          limit: 255
    t.string   "image_url",    limit: 255
    t.string   "description",  limit: 255
    t.text     "other",        limit: 65535
    t.text     "credentials",  limit: 65535
    t.text     "raw_info",     limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "social_profiles", ["provider", "uid"], name: "index_social_profiles_on_provider_and_uid", unique: true, using: :btree
  add_index "social_profiles", ["user_id"], name: "index_social_profiles_on_user_id", using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.string   "taggable_type", limit: 191
    t.integer  "tagger_id",     limit: 4
    t.string   "tagger_type",   limit: 191
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count", limit: 4,   default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 190, default: "", null: false
    t.string   "encrypted_password",     limit: 190, default: "", null: false
    t.string   "reset_password_token",   limit: 190
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "token",                  limit: 190,              null: false
    t.string   "uid",                    limit: 160,              null: false
    t.string   "provider",               limit: 30,               null: false
    t.string   "name",                   limit: 255
    t.string   "image",                  limit: 255
    t.string   "description",            limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["token"], name: "index_users_on_token", unique: true, using: :btree
  add_index "users", ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true, using: :btree

end
