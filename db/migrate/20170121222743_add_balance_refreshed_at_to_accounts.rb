class AddBalanceRefreshedAtToAccounts < ActiveRecord::Migration[5.0]
  def change
  	add_column :accounts, :balance_refreshed_at, :datetime
  end
end
