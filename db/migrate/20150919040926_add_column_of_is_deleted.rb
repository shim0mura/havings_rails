class AddColumnOfIsDeleted < ActiveRecord::Migration
  def change
    add_column :items, :is_deleted, :boolean, null: false, default: false
  end
end
