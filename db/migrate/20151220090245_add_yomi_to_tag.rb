class AddYomiToTag < ActiveRecord::Migration
  def change
    add_column :tags, :yomi_jp, :string
    add_column :tags, :yomi_roma, :string
    add_column :tags, :tag_cluster_id, :integer
  end
end
