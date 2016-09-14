class AddClassedTagIdToItem < ActiveRecord::Migration
  def change
    add_column :items, :classed_tag_id, :integer
  end
end
