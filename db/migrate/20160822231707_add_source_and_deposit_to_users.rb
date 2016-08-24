class AddSourceAndDepositToUsers < ActiveRecord::Migration
  def change
    add_column :users, :source_account_id, :uuid
    add_column :users, :deposit_account_id, :uuid
    add_index :users, :source_account_id
    add_index :users, :deposit_account_id
  end
end
