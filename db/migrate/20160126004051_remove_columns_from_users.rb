class RemoveColumnsFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :address, :string
    remove_column :users, :city, :string
    remove_column :users, :state, :string
    remove_column :users, :zip, :string
  end
end
