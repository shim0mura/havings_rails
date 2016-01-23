class CreateTagMigrationHistories < ActiveRecord::Migration
  def change
    create_table :tag_migration_histories do |t|
      t.text :added_tags
      t.text :updated_tags
      t.text :deleted_tags

      t.timestamps null: false
    end
  end
end
