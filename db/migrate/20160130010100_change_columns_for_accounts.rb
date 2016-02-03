class ChangeColumnsForAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :account, :integer
    add_column :accounts, :account_num, :integer, :limit => 8
  end
end
