class RemoveAccountsFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :accounts
  end
end
