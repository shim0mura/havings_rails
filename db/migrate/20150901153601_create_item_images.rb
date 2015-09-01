class CreateItemImages < ActiveRecord::Migration
  def change
    create_table :item_images do |t|
      t.string :image
      t.integer :item_id

      t.timestamps null: false
    end
  end
end
