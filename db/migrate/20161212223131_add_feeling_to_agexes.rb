class AddFeelingToAgexes < ActiveRecord::Migration[5.0]
  def change
    add_column :agexes, :feeling, :integer, default: 0
  end
end
