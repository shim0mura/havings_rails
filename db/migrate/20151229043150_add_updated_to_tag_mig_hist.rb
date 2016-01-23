class AddUpdatedToTagMigHist < ActiveRecord::Migration
  def change
    add_column :tag_migration_histories, :tag_changed_at, :datetime
  end
end
