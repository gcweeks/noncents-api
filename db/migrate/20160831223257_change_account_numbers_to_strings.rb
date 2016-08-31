class ChangeAccountNumbersToStrings < ActiveRecord::Migration
  def change
    remove_column :accounts, :account_num, :integer
    remove_column :accounts, :routing_num, :integer
    add_column :accounts, :account_num, :string
    add_column :accounts, :routing_num, :string
  end
end
