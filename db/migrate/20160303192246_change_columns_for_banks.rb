class ChangeColumnsForBanks < ActiveRecord::Migration
  def change
    add_reference :banks, :user, index: true, foreign_key: true
    add_column :banks, :access_token, :string
  end
end
