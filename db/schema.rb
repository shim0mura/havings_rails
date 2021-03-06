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

ActiveRecord::Schema.define(version: 20160914070239) do

  create_table "charts", force: :cascade do |t|
    t.integer  "user_id",      limit: 4,     null: false
    t.text     "chart_detail", limit: 65535
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "charts", ["user_id"], name: "index_charts_on_user_id", unique: true, using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,                     null: false
    t.integer  "item_id",    limit: 4,                     null: false
    t.text     "content",    limit: 65535
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.boolean  "is_deleted", limit: 1,     default: false, null: false
  end

  create_table "device_tokens", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "token",       limit: 255
    t.integer  "device_type", limit: 4
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.boolean  "is_enable",   limit: 1,   default: true, null: false
  end

  add_index "device_tokens", ["user_id", "token"], name: "index_device_tokens_on_user_id_and_token", unique: true, using: :btree
  add_index "device_tokens", ["user_id"], name: "index_device_tokens_on_user_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.integer  "event_type",       limit: 4,                     null: false
    t.integer  "acter_id",         limit: 4,                     null: false
    t.integer  "suffered_user_id", limit: 4
    t.text     "properties",       limit: 65535
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "related_id",       limit: 4
    t.boolean  "is_deleted",       limit: 1,     default: false, null: false
  end

  add_index "events", ["acter_id"], name: "index_events_on_acter_id", using: :btree
  add_index "events", ["event_type"], name: "index_events_on_event_type", using: :btree
  add_index "events", ["related_id"], name: "index_events_on_related_id", using: :btree

  create_table "favorites", force: :cascade do |t|
    t.integer  "user_id",    limit: 4, null: false
    t.integer  "item_id",    limit: 4, null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "favorites", ["user_id", "item_id"], name: "index_favorites_on_user_id_and_item_id", unique: true, using: :btree

  create_table "follows", force: :cascade do |t|
    t.integer  "following_user_id", limit: 4, null: false
    t.integer  "followed_user_id",  limit: 4, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "follows", ["followed_user_id"], name: "index_follows_on_followed_user_id", using: :btree
  add_index "follows", ["following_user_id", "followed_user_id"], name: "index_follows_on_following_user_id_and_followed_user_id", unique: true, using: :btree
  add_index "follows", ["following_user_id"], name: "index_follows_on_following_user_id", using: :btree

  create_table "image_favorites", force: :cascade do |t|
    t.integer  "user_id",       limit: 4, null: false
    t.integer  "item_id",       limit: 4, null: false
    t.integer  "item_image_id", limit: 4, null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "image_favorites", ["user_id", "item_image_id"], name: "index_image_favorites_on_user_id_and_item_image_id", unique: true, using: :btree

  create_table "item_images", force: :cascade do |t|
    t.string   "image",      limit: 255
    t.integer  "item_id",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.datetime "added_at",               null: false
    t.string   "memo",       limit: 255
  end

  create_table "items", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.text     "description",      limit: 65535
    t.boolean  "is_list",          limit: 1,     default: false, null: false
    t.boolean  "is_garbage",       limit: 1,     default: false, null: false
    t.integer  "count",            limit: 4,     default: 1,     null: false
    t.text     "garbage_reason",   limit: 65535
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "user_id",          limit: 4,                     null: false
    t.integer  "list_id",          limit: 4
    t.integer  "private_type",     limit: 4,     default: 0,     null: false
    t.boolean  "is_deleted",       limit: 1,     default: false, null: false
    t.text     "count_properties", limit: 65535
    t.integer  "classed_tag_id",   limit: 4
  end

  create_table "notifications", force: :cascade do |t|
    t.integer  "user_id",       limit: 4,   null: false
    t.string   "unread_events", limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "read_events",   limit: 255
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

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

  create_table "tag_migration_histories", force: :cascade do |t|
    t.text     "added_tags",     limit: 65535
    t.text     "updated_tags",   limit: 65535
    t.text     "deleted_tags",   limit: 65535
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "tag_changed_at"
  end

  create_table "tag_relations", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4, null: false
    t.integer  "parent_tag_id", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "relation_type", limit: 4
  end

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
    t.string   "name",           limit: 255
    t.integer  "taggings_count", limit: 4,   default: 0
    t.string   "yomi_jp",        limit: 255
    t.string   "yomi_roma",      limit: 255
    t.integer  "parent_id",      limit: 4
    t.integer  "tag_type",       limit: 4
    t.integer  "priority",       limit: 4
    t.integer  "nest",           limit: 4
    t.boolean  "is_default_tag", limit: 1,   default: false, null: false
    t.boolean  "is_deleted",     limit: 1,   default: false, null: false
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "timers", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "list_id",        limit: 4,                     null: false
    t.integer  "user_id",        limit: 4,                     null: false
    t.datetime "next_due_at",                                  null: false
    t.datetime "over_due_from"
    t.boolean  "is_repeating",   limit: 1,     default: false, null: false
    t.text     "properties",     limit: 65535
    t.boolean  "is_deleted",     limit: 1,     default: false, null: false
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.boolean  "is_active",      limit: 1,     default: true,  null: false
    t.datetime "latest_calc_at",                               null: false
  end

  add_index "timers", ["list_id"], name: "index_timers_on_list_id", using: :btree
  add_index "timers", ["user_id"], name: "index_timers_on_user_id", using: :btree

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

  create_table "yahoo_categories", force: :cascade do |t|
    t.string   "category_name",        limit: 255
    t.string   "category_name_jp",     limit: 255
    t.string   "category_name_roma",   limit: 255
    t.string   "url",                  limit: 255
    t.integer  "category_id_by_yahoo", limit: 4
    t.integer  "parent_id",            limit: 4
    t.boolean  "is_end",               limit: 1,     default: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "root_category_id",     limit: 4
    t.boolean  "is_brand",             limit: 1,     default: false
    t.text     "duplicates",           limit: 65535
    t.integer  "depth",                limit: 4
    t.boolean  "is_default_tag",       limit: 1,     default: false
    t.integer  "tag_type",             limit: 4
    t.integer  "tagging_flag",         limit: 4
    t.integer  "tagged_depth",         limit: 4
  end

end
