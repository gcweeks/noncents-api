class AddGoalToUsers < ActiveRecord::Migration
  def change
    add_column :users, :goal, :integer, default: 230
  end
end
