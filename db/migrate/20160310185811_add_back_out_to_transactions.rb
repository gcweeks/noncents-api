class AddBackOutToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :backed_out, :boolean, default: false
  end
end
