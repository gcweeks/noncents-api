class ChangeColumnsForVices < ActiveRecord::Migration
  def change
    remove_column :vices, :user_id
  end
end
