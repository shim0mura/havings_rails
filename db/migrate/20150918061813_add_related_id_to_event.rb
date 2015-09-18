class AddRelatedIdToEvent < ActiveRecord::Migration
  def change
    add_column :events, :related_id, :integer

    add_index :events, :related_id
  end
end
