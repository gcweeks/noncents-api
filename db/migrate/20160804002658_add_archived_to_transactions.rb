class AddArchivedToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :archived, :boolean, default: false
  end
end
