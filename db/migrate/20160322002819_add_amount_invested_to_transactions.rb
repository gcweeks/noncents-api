class AddAmountInvestedToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :amount_invested, :decimal, default: 0
  end
end
