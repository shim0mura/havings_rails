class AddDefaultFlgToTag < ActiveRecord::Migration
  def change
    add_column :tags, :is_default_tag, :boolean, default: false, null: false
    add_column :tags, :is_deleted, :boolean, default: false, null: false
    rename_column :tags, :type, :tag_type
    add_column :tag_relations, :relation_type, :integer
  end
end
