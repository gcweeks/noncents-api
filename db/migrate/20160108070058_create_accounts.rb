class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.belongs_to :user, index: true, foreign_key: true
      t.string :acctNum
      t.string :routNum
      t.string :cardNum
      t.string :cardName
      t.integer :expMonth
      t.integer :expYear
      t.string :zipcode

      t.timestamps null: false
    end
  end
end
