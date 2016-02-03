class RemoveColumnsFromAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :acctNum, :string
    remove_column :accounts, :routNum, :string
    remove_column :accounts, :cardNum, :string
    remove_column :accounts, :cardName, :string
    remove_column :accounts, :expMonth, :string
    remove_column :accounts, :expYear, :string
    remove_column :accounts, :zipcode, :string
  end
end
