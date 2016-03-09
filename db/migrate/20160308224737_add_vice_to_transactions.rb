class AddViceToTransactions < ActiveRecord::Migration
  def change
    add_reference :vices, :transaction, index: true
  end
end
