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

ActiveRecord::Schema.define(version: 20160922043633) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "plaid_id"
    t.string   "name"
    t.string   "institution"
    t.decimal  "available_balance"
    t.decimal  "current_balance"
    t.string   "account_type"
    t.string   "account_subtype"
    t.boolean  "tracking",          default: false
    t.string   "dwolla_id"
    t.string   "account_num"
    t.string   "routing_num"
    t.uuid     "user_id"
    t.uuid     "bank_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.index ["bank_id"], name: "index_accounts_on_bank_id", using: :btree
    t.index ["user_id"], name: "index_accounts_on_user_id", using: :btree
  end

  create_table "addresses", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "line1"
    t.string   "line2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.uuid     "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "agexes", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.decimal  "amount",     default: "0.0"
    t.date     "month"
    t.uuid     "user_id"
    t.uuid     "vice_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["user_id"], name: "index_agexes_on_user_id", using: :btree
  end

  create_table "auth_events", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.inet     "ip_address"
    t.boolean  "success"
    t.uuid     "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_auth_events_on_user_id", using: :btree
  end

  create_table "banks", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.string   "access_token"
    t.uuid     "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["user_id"], name: "index_banks_on_user_id", using: :btree
  end

  create_table "dwolla_transactions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "dwolla_id"
    t.string   "balance"
    t.string   "source"
    t.string   "deposit"
    t.string   "amount"
    t.uuid     "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_dwolla_transactions_on_user_id", using: :btree
  end

  create_table "fcm_tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "token"
    t.uuid     "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "funds", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.decimal  "balance",         default: "0.0"
    t.decimal  "amount_invested", default: "0.0"
    t.uuid     "user_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "transactions", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "plaid_id"
    t.date     "date"
    t.decimal  "amount"
    t.string   "name"
    t.string   "category_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "invested",        default: false
    t.boolean  "backed_out",      default: false
    t.decimal  "amount_invested", default: "0.0"
    t.boolean  "archived",        default: false
    t.uuid     "account_id"
    t.uuid     "user_id"
    t.uuid     "vice_id"
    t.index ["account_id"], name: "index_transactions_on_account_id", using: :btree
    t.index ["user_id"], name: "index_transactions_on_user_id", using: :btree
  end

  create_table "user_vices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.uuid     "user_id"
    t.uuid     "vice_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_vices_on_user_id", using: :btree
    t.index ["vice_id"], name: "index_user_vices_on_vice_id", using: :btree
  end

  create_table "users", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "fname"
    t.string   "lname"
    t.string   "token"
    t.string   "email",                     default: "",  null: false
    t.string   "password_digest",           default: "",  null: false
    t.date     "dob"
    t.integer  "invest_percent",            default: 0
    t.datetime "transactions_refreshed_at"
    t.integer  "goal",                      default: 150
    t.string   "dwolla_id"
    t.string   "phone"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string   "confirmation_token"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",           default: 0,   null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.uuid     "source_account_id"
    t.uuid     "deposit_account_id"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
  end

  create_table "vices", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "yearly_funds", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
    t.decimal  "balance",         default: "0.0"
    t.decimal  "amount_invested", default: "0.0"
    t.integer  "year"
    t.uuid     "user_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.index ["user_id"], name: "index_yearly_funds_on_user_id", using: :btree
  end

end
