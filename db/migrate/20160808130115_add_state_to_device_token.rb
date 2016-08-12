class AddStateToDeviceToken < ActiveRecord::Migration
  def change
    add_column :device_tokens, :is_enable, :string
  end
end
