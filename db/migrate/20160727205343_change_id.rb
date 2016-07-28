class ChangeId < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'

    add_column :accounts, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :accounts, :user_uuid, :uuid
    change_table :accounts do |t|
      execute "ALTER TABLE accounts DROP id CASCADE"
      t.rename :uuid, :id
      t.remove :user_id
      t.rename :user_uuid, :user_id
    end
    execute "ALTER TABLE accounts ADD PRIMARY KEY (id);"
    add_column :addresses, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :addresses, :user_uuid, :uuid
    change_table :addresses do |t|
      execute "ALTER TABLE addresses DROP id CASCADE"
      t.rename :uuid, :id
    end
    execute "ALTER TABLE addresses ADD PRIMARY KEY (id);"
    add_column :agexes, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :agexes, :user_uuid, :uuid
    add_column :agexes, :vice_uuid, :uuid
    change_table :agexes do |t|
      execute "ALTER TABLE agexes DROP id CASCADE"
      t.rename :uuid, :id
      t.remove :user_id
      t.rename :user_uuid, :user_id
      t.remove :vice_id
      t.rename :vice_uuid, :vice_id
    end
    execute "ALTER TABLE agexes ADD PRIMARY KEY (id);"
    add_column :banks, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :banks, :user_uuid, :uuid
    change_table :banks do |t|
      execute "ALTER TABLE banks DROP id CASCADE"
      t.rename :uuid, :id
      t.remove :user_id
      t.rename :user_uuid, :user_id
    end
    execute "ALTER TABLE banks ADD PRIMARY KEY (id);"
    add_column :funds, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :funds, :user_uuid, :uuid
    change_table :funds do |t|
      execute "ALTER TABLE funds DROP id CASCADE"
      t.rename :uuid, :id
      t.remove :user_id
      t.rename :user_uuid, :user_id
    end
    execute "ALTER TABLE funds ADD PRIMARY KEY (id);"
    add_column :transactions, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :transactions, :account_uuid, :uuid
    add_column :transactions, :user_uuid, :uuid
    add_column :transactions, :vice_uuid, :uuid
    change_table :transactions do |t|
      execute "ALTER TABLE transactions DROP id CASCADE"
      t.rename :uuid, :id
      t.remove :account_id
      t.rename :account_uuid, :account_id
      t.remove :user_id
      t.rename :user_uuid, :user_id
      t.remove :vice_id
      t.rename :vice_uuid, :vice_id
    end
    execute "ALTER TABLE transactions ADD PRIMARY KEY (id);"
    add_column :user_friends, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :user_friends, :user_uuid, :uuid
    add_column :user_friends, :friend_uuid, :uuid
    change_table :user_friends do |t|
      execute "ALTER TABLE user_friends DROP id CASCADE"
      t.rename :uuid, :id
      t.remove :user_id
      t.rename :user_uuid, :user_id
      t.remove :friend_id
      t.rename :friend_uuid, :friend_id
    end
    execute "ALTER TABLE user_friends ADD PRIMARY KEY (id);"
    add_column :user_vices, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :user_vices, :user_uuid, :uuid
    add_column :user_vices, :vice_uuid, :uuid
    change_table :user_vices do |t|
      execute "ALTER TABLE user_vices DROP id CASCADE"
      t.rename :uuid, :id
      t.remove :user_id
      t.rename :user_uuid, :user_id
      t.remove :vice_id
      t.rename :vice_uuid, :vice_id
    end
    execute "ALTER TABLE user_vices ADD PRIMARY KEY (id);"
    add_column :users, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    change_table :users do |t|
      execute "ALTER TABLE users DROP id CASCADE"
      t.rename :uuid, :id
    end
    execute "ALTER TABLE users ADD PRIMARY KEY (id);"
    add_column :vices, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    change_table :vices do |t|
      execute "ALTER TABLE vices DROP id CASCADE"
      t.rename :uuid, :id
    end
    execute "ALTER TABLE vices ADD PRIMARY KEY (id);"
    add_column :yearly_funds, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    add_column :yearly_funds, :user_uuid, :uuid
    change_table :yearly_funds do |t|
      execute "ALTER TABLE yearly_funds DROP id CASCADE"
      t.rename :uuid, :id
      t.remove :user_id
      t.rename :user_uuid, :user_id
    end
    execute "ALTER TABLE yearly_funds ADD PRIMARY KEY (id);"
  end
end
