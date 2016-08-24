class AddTrackingToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :tracking, :boolean, default: false
  end
end
