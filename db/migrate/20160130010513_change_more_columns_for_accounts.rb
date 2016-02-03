class ChangeMoreColumnsForAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :routing, :integer
    add_column :accounts, :routing_num, :integer
  end
end
