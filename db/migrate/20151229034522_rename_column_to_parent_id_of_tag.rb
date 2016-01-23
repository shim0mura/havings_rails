class RenameColumnToParentIdOfTag < ActiveRecord::Migration
  def change
    rename_column :tags, :tag_relation_id, :parent_id
  end
end
