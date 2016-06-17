class ChangeDefaultUserGoal < ActiveRecord::Migration
  def change
    change_column_default :users, :goal, 150
  end
end
