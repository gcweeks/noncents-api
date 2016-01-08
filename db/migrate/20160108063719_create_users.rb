class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :fname
      t.string :lname
      t.string :number
      t.string :address
      t.string :city
      t.string :state
      t.string :zip
      t.string :dob
      t.string :number
      t.integer :accounts
      t.string :token

      t.timestamps null: false
    end
  end
end
