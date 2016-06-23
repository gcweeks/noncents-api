class CreateYearlyFunds < ActiveRecord::Migration
  def change
    create_table :yearly_funds do |t|
      t.decimal :balance, default: 0
      t.decimal :amount_invested, default: 0
      t.integer :year
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
