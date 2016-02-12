class ChangeDobColumnForUsers < ActiveRecord::Migration
  def change
    remove_column :users, :dob, :string
    add_column :users, :dob, :date
  end
end
