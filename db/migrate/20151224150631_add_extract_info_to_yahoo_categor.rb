class AddExtractInfoToYahooCategor < ActiveRecord::Migration
  def change
    rename_column :yahoo_categories, :type, :tag_type
  end
end
