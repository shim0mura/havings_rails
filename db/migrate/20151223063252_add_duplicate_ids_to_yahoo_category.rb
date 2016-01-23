class AddDuplicateIdsToYahooCategory < ActiveRecord::Migration
  def change
    add_column :yahoo_categories, :duplicates, :string
  end
end
