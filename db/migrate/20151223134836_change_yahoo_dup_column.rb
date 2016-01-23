class ChangeYahooDupColumn < ActiveRecord::Migration
  def change
    change_column :yahoo_categories, :duplicates, :text
  end
end
