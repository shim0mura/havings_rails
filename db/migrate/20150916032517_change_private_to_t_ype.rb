class ChangePrivateToTYpe < ActiveRecord::Migration
  def change
    remove_column :items, :is_private
    add_column :items, :private_type, :integer, null: false, default: 1
  end
end
