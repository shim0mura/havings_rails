class CreateYahooCategories < ActiveRecord::Migration
  def change
    create_table :yahoo_categories do |t|
      t.string :category_name
      t.string :category_name_jp
      t.string :category_name_roma
      t.string :url
      t.integer :category_id
      t.integer :parent_id
      t.boolean :is_end

      t.timestamps null: false
    end
  end
end
