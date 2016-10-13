class AddPlaidProductStatusToBanks < ActiveRecord::Migration[5.0]
  def change
    add_column :banks, :plaid_auth, :boolean, default: false
    add_column :banks, :plaid_connect, :boolean, default: false
  end
end
