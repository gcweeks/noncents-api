class AddAmountInvestedToFunds < ActiveRecord::Migration
  def change
    add_column :funds, :amount_invested, :decimal, default: 0
  end
end
