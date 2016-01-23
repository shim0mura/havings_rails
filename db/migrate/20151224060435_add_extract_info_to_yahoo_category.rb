class AddExtractInfoToYahooCategory < ActiveRecord::Migration
  def change
    add_column :yahoo_categories, :is_default_tag, :boolean, default: false
    add_column :yahoo_categories, :type, :integer
  end
end
