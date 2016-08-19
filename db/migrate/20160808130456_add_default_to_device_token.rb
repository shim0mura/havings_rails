class AddDefaultToDeviceToken < ActiveRecord::Migration
  def change

    change_column :device_tokens, :is_enable, :boolean, null: false, default: true
  end
end
