class InitialMigration < ActiveRecord::Migration[5.0]
  def change
    enable_extension "plpgsql"
    enable_extension "uuid-ossp"

    create_table :accounts, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string  :plaid_id
      t.string  :name
      t.string  :institution
      t.decimal :available_balance
      t.decimal :current_balance
      t.string  :account_type
      t.string  :account_subtype
      t.boolean :tracking, default: false
      t.string  :dwolla_id
      t.string  :account_num
      t.string  :routing_num
      t.uuid    :user_id
      t.uuid    :bank_id

      t.timestamps null: false

      t.index :user_id
      t.index :bank_id
    end

    create_table :addresses, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string :line1
      t.string :line2
      t.string :city
      t.string :state
      t.string :zip
      t.uuid   :user_id

      t.timestamps null: false
    end

    create_table :agexes, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.decimal :amount, default: 0.0
      t.date    :month
      t.uuid    :user_id
      t.uuid    :vice_id

      t.timestamps null: false

      t.index :user_id
    end

    create_table :banks, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string :name
      t.string :access_token
      t.uuid   :user_id

      t.timestamps null: false

      t.index :user_id
    end

    create_table :dwolla_transactions, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string :dwolla_id
      t.string :balance
      t.string :source
      t.string :deposit
      t.string :amount
      t.uuid   :user_id

      t.timestamps null: false

      t.index :user_id
    end

    create_table :fcm_tokens, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string :token
      t.uuid   :user_id

      t.timestamps null: false
    end

    create_table :funds, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.decimal :balance, default: 0.0
      t.decimal :amount_invested, default: 0.0
      t.uuid    :user_id

      t.timestamps null: false
    end

    create_table :transactions, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string   :plaid_id
      t.date     :date
      t.decimal  :amount
      t.string   :name
      t.string   :category_id
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.boolean  :invested, default: false
      t.boolean  :backed_out, default: false
      t.decimal  :amount_invested, default: 0.0
      t.boolean  :archived, default: false
      t.uuid     :account_id
      t.uuid     :user_id
      t.uuid     :vice_id

      t.timestamps null: false

      t.index :account_id
      t.index :user_id
    end

    create_table :user_vices, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.uuid :user_id
      t.uuid :vice_id

      t.timestamps null: false

      t.index :user_id
      t.index :vice_id
    end

    create_table :users, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string   :fname
      t.string   :lname
      t.string   :token
      t.string   :email, default: '', null: false
      t.string   :password_digest, default: '', null: false
      t.date     :dob
      t.integer  :invest_percent, default: 0
      t.datetime :transactions_refreshed_at
      t.integer  :goal, default: 150
      t.string   :dwolla_id
      t.string   :phone
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.string   :confirmation_token
      t.datetime :confirmation_sent_at
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at
      t.uuid     :source_account_id
      t.uuid     :deposit_account_id

      t.timestamps null: false

      t.index :email, unique: true
    end

    create_table :vices, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string :name

      t.timestamps null: false
    end

    create_table :yearly_funds, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.decimal :balance, default: 0.0
      t.decimal :amount_invested, default: 0.0
      t.integer :year
      t.uuid    :user_id

      t.timestamps null: false

      t.index :user_id
    end
  end
end
