class ChangeColumnForUsers < ActiveRecord::Migration
  def change
    remove_column :users, :invest_percent, :integer
    add_column :users, :invest_percent, :integer, :default => 0
  end
end
