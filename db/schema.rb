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

ActiveRecord::Schema.define(version: 20160804002658) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "plaid_id"
    t.string   "name"
    t.string   "institution"
    t.decimal  "available_balance"
    t.decimal  "current_balance"
    t.integer  "account_num",       limit: 8
    t.integer  "routing_num"
    t.string   "account_type"
    t.string   "account_subtype"
    t.uuid     "user_id"
  end

  create_table "addresses", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.string   "line1"
    t.string   "line2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "user_uuid"
  end

  add_index "addresses", ["user_id"], name: "index_addresses_on_user_id", using: :btree

  create_table "agexes", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.decimal  "amount",     default: 0.0
    t.date     "month"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.uuid     "user_id"
    t.uuid     "vice_id"
  end

  create_table "banks", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "access_token"
    t.uuid     "user_id"
  end

  create_table "funds", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.decimal  "balance",         default: 0.0
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.decimal  "amount_invested", default: 0.0
    t.uuid     "user_id"
  end

  create_table "transactions", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.string   "plaid_id"
    t.date     "date"
    t.decimal  "amount"
    t.string   "name"
    t.string   "category_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "invested",        default: false
    t.boolean  "backed_out",      default: false
    t.decimal  "amount_invested", default: 0.0
    t.uuid     "account_id"
    t.uuid     "user_id"
    t.uuid     "vice_id"
    t.boolean  "archived",        default: false
  end

  create_table "user_friends", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "user_id"
    t.uuid     "friend_id"
  end

  create_table "user_vices", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid     "user_id"
    t.uuid     "vice_id"
  end

  create_table "users", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.string   "fname"
    t.string   "lname"
    t.string   "number"
    t.string   "token"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "email"
    t.string   "password_digest"
    t.date     "dob"
    t.integer  "invest_percent",  default: 0
    t.datetime "sync_date"
    t.integer  "goal",            default: 150
    t.string   "fcm_key"
  end

  create_table "vices", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name"
  end

  create_table "yearly_funds", id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
    t.decimal  "balance",         default: 0.0
    t.decimal  "amount_invested", default: 0.0
    t.integer  "year"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.uuid     "user_id"
  end

end
