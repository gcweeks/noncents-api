class AddFcmTokensToUsers < ActiveRecord::Migration
  def change
    remove_column :users, :fcm_key, :string
    add_column :users, :fcm_tokens, :string, array: true, default: []
  end
end
