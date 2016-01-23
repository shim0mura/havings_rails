class AddColumnsToYahooCategory < ActiveRecord::Migration
  def change
    add_column :yahoo_categories, :root_category_id, :integer
    add_column :yahoo_categories, :is_brand, :boolean, default: false
    rename_column :yahoo_categories, :category_id, :category_id_by_yahoo
    change_column :yahoo_categories, :is_end, :boolean, default: false
  end
end
