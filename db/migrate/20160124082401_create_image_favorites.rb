class CreateImageFavorites < ActiveRecord::Migration
  def change
    create_table :image_favorites do |t|
      t.integer :user_id, null: false
      t.integer :item_id, null: false
      t.integer :item_image_id, null: false

      t.timestamps null: false
    end

    add_index :image_favorites, [:user_id, :item_image_id], unique: true
  end
end
