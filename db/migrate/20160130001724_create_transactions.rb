class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :plaid_id
      t.date :date
      t.decimal :amount
      t.string :name
      t.string :category_id
      t.references :account, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
