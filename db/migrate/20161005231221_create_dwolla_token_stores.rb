class CreateDwollaTokenStores < ActiveRecord::Migration[5.0]
  def change
    create_table :dwolla_token_stores, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string  :encrypted_access_token
      t.string  :encrypted_access_token_salt
      t.string  :encrypted_access_token_iv
      t.string  :encrypted_refresh_token
      t.string  :encrypted_refresh_token_salt
      t.string  :encrypted_refresh_token_iv
      t.integer :expires_in
      t.string  :scope
      t.string  :account_id

      t.timestamps
    end
  end
end
