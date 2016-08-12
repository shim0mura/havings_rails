class CreateDeviceTokens < ActiveRecord::Migration
  def change
    create_table :device_tokens do |t|
      t.integer :user_id
      t.string :token
      t.integer :type

      t.timestamps null: false
    end

    add_index :device_tokens, :user_id
  end
end
