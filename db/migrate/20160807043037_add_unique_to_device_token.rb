class AddUniqueToDeviceToken < ActiveRecord::Migration
  def change
    add_index :device_tokens, [:user_id, :token], unique: true
    rename_column :device_tokens, :type, :device_type
  end
end
