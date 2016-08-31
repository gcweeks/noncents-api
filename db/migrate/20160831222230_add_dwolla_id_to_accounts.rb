class AddDwollaIdToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :dwolla_id, :string
  end
end
