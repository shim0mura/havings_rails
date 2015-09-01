class DeleteListIdFromItem < ActiveRecord::Migration
  def change
    remove_column :items, :list_id
  end
end
