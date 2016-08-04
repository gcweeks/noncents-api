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

  create_table "accounts", force: :cascade do |t|
    t.integer  "user_id"
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
  end

  add_index "accounts", ["user_id"], name: "index_accounts_on_user_id"

  create_table "addresses", force: :cascade do |t|
    t.string   "line1"
    t.string   "line2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "addresses", ["user_id"], name: "index_addresses_on_user_id"

  create_table "agexes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "vice_id"
    t.decimal  "amount",     default: 0.0
    t.date     "month"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "agexes", ["user_id"], name: "index_agexes_on_user_id"
  add_index "agexes", ["vice_id"], name: "index_agexes_on_vice_id"

  create_table "banks", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "user_id"
    t.string   "access_token"
  end

  add_index "banks", ["user_id"], name: "index_banks_on_user_id"

  create_table "funds", force: :cascade do |t|
    t.decimal  "balance",         default: 0.0
    t.integer  "user_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.decimal  "amount_invested", default: 0.0
  end

  add_index "funds", ["user_id"], name: "index_funds_on_user_id"

  create_table "transactions", force: :cascade do |t|
    t.string   "plaid_id"
    t.date     "date"
    t.decimal  "amount"
    t.string   "name"
    t.string   "category_id"
    t.integer  "account_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "user_id"
    t.boolean  "invested",        default: false
    t.boolean  "backed_out",      default: false
    t.integer  "vice_id"
    t.decimal  "amount_invested", default: 0.0
    t.boolean  "archived",        default: false
  end

  add_index "transactions", ["account_id"], name: "index_transactions_on_account_id"
  add_index "transactions", ["user_id"], name: "index_transactions_on_user_id"
  add_index "transactions", ["vice_id"], name: "index_transactions_on_vice_id"

  create_table "user_friends", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_vices", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "vice_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
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
  end

  create_table "vices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "name"
  end

  create_table "yearly_funds", force: :cascade do |t|
    t.decimal  "balance",         default: 0.0
    t.decimal  "amount_invested", default: 0.0
    t.integer  "year"
    t.integer  "user_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "yearly_funds", ["user_id"], name: "index_yearly_funds_on_user_id"

end
