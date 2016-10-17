class RemoveSaltsFromDwollaTokenStore < ActiveRecord::Migration[5.0]
  def change
    remove_column :dwolla_token_stores, :encrypted_access_token_salt
    remove_column :dwolla_token_stores, :encrypted_refresh_token_salt
  end
end
