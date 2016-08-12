class AddDefaultToDeviceToken < ActiveRecord::Migration
  def change

    add_column :device_tokens, :is_enable, :boolean, null: false, default: true
  end
end
