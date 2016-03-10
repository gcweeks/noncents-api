class CreateFunds < ActiveRecord::Migration
  def change
    create_table :funds do |t|
      t.decimal :balance, default: 0
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
