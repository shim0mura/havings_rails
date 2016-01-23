class AddTaggingColumnToYahooCategory < ActiveRecord::Migration
  def change
    add_column :yahoo_categories, :tagging_flag, :integer
    add_column :yahoo_categories, :tagged_depth, :integer
  end
end
