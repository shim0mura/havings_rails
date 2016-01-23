class AddMetadataToItemImage < ActiveRecord::Migration
  def change
    add_column :item_images, :added_at, :datetime, null: false
    add_column :item_images, :memo, :string
  end
end
