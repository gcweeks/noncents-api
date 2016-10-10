class AddAccountNumShortToAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :account_num_short, :string
  end
end
