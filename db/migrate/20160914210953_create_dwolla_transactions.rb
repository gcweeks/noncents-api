class CreateDwollaTransactions < ActiveRecord::Migration
  def change
    create_table :dwolla_transactions, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.string :dwolla_id
      t.string :balance
      t.string :source
      t.string :deposit
      t.string :amount

      t.timestamps null: false
    end
  end
end
