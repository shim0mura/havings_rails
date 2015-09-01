class CreateItemLists < ActiveRecord::Migration
  def change
    create_table :item_lists do |t|
      t.integer :item_id, null: false
      t.integer :list_id, null: false

      t.timestamps null: false
    end
  end
end
