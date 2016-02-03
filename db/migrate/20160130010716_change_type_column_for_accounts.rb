class ChangeTypeColumnForAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :type, :string
    add_column :accounts, :account_type, :string
  end
end
