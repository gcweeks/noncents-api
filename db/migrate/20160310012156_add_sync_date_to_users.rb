class AddSyncDateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :sync_date, :datetime
  end
end
