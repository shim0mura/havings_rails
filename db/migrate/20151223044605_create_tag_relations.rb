class CreateTagRelations < ActiveRecord::Migration
  def change
    create_table :tag_relations do |t|
      t.integer :tag_id, null: false
      t.integer :parent_tag_id

      t.timestamps null: false
    end
  end
end
