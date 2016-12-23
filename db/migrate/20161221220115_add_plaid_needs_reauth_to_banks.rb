class AddPlaidNeedsReauthToBanks < ActiveRecord::Migration[5.0]
  def change
    add_column :banks, :plaid_needs_reauth, :boolean, default: false
  end
end
