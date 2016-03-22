class CreateAgexes < ActiveRecord::Migration
  def change
    create_table :agexes do |t|
      t.references :user, index: true, foreign_key: true
      t.references :vice, index: true, foreign_key: true
      t.decimal :amount, default: 0
      t.date :month

      t.timestamps null: false
    end
  end
end
