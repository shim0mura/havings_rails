class AddDeletedToComment < ActiveRecord::Migration
  def change
    add_column :comments, :is_deleted, :boolean, null: false, default: false
  end
end
