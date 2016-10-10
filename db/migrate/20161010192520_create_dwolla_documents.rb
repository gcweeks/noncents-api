class CreateDwollaDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :dwolla_documents do |t|
      t.string :dwolla_id
      t.uuid   :user_id

      t.timestamps

      t.index :user_id
    end
  end
end
