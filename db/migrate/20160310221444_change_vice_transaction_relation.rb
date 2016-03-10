class ChangeViceTransactionRelation < ActiveRecord::Migration
  def change
    remove_reference :vices, :transaction, index: true
    add_reference :transactions, :vice, index: true
  end
end
