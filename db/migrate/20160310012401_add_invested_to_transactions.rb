class AddInvestedToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :invested, :boolean, default: false
  end
end
