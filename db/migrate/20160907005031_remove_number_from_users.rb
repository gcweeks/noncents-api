class RemoveNumberFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :number, :string
  end
end
