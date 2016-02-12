class CreateUserVices < ActiveRecord::Migration
  def change
    create_table :user_vices do |t|
      t.integer :user_id
      t.integer :vice_id

      t.timestamps null: false
    end
  end
end
