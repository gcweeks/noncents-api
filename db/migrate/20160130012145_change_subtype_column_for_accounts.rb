class ChangeSubtypeColumnForAccounts < ActiveRecord::Migration
  def change
    remove_column :accounts, :subtype, :string
    add_column :accounts, :account_subtype, :string
  end
end
