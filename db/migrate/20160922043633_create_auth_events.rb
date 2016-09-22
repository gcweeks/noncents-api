class CreateAuthEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :auth_events, id: :uuid, default: "uuid_generate_v4()" do |t|
      t.inet    :ip_address
      t.boolean :success
      t.uuid    :user_id

      t.timestamps

      t.index :user_id
    end
  end
end
