class DropItemList < ActiveRecord::Migration
  def change
    drop_table :item_lists
    add_column :items, :list_id, :integer
  end
end
