class AddDwollaStatusToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :dwolla_status, :string
  end
end
