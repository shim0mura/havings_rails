class AddDepthToYahooCategory < ActiveRecord::Migration
  def change
    add_column :yahoo_categories, :depth, :integer
  end
end
