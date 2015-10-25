class AddColumnCountPropertiesToItem < ActiveRecord::Migration
  def change
    add_column :items, :count_properties, :text
  end
end
