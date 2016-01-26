class AddNameToVices < ActiveRecord::Migration
  def change
    add_column :vices, :name, :string
  end
end
