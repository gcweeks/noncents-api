class CreateFcmTokens < ActiveRecord::Migration
  def change
    create_table :fcm_tokens do |t|
      t.string :token
      t.uuid :user_id

      t.timestamps null: false
    end
    add_index :fcm_tokens, :token
  end
end
