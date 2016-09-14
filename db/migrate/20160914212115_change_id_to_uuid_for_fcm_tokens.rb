class ChangeIdToUuidForFcmTokens < ActiveRecord::Migration
  def change
    add_column :fcm_tokens, :uuid, :uuid, default: "uuid_generate_v4()", null: false
    change_table :fcm_tokens do |t|
      execute "ALTER TABLE fcm_tokens DROP id CASCADE"
      t.rename :uuid, :id
    end
    execute "ALTER TABLE fcm_tokens ADD PRIMARY KEY (id);"
  end
end
