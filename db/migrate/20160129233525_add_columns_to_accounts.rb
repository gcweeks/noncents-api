class AddColumnsToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :plaid_id, :string
    add_column :accounts, :name, :string
    add_column :accounts, :type, :string
    add_column :accounts, :subtype, :string
    add_column :accounts, :institution, :string
    add_column :accounts, :routing, :integer
    add_column :accounts, :account, :integer
    add_column :accounts, :available_balance, :decimal
    add_column :accounts, :current_balance, :decimal
  end
end
