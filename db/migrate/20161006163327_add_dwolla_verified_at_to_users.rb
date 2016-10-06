class AddDwollaVerifiedAtToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :dwolla_verified_at, :datetime
  end
end
