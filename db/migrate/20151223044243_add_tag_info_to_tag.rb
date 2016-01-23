class AddTagInfoToTag < ActiveRecord::Migration
  def change
    add_column :tags, :type, :integer
    add_column :tags, :priority, :integer
    add_column :tags, :nest, :integer
    rename_column :tags, :tag_cluster_id, :tag_relation_id
  end
end
