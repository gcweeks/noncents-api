class AddFcmKeyToUser < ActiveRecord::Migration
  def change
    add_column :users, :fcm_key, :string
  end
end
