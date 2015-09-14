class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :user_id, null: false
      t.text :events

      t.timestamps null: false
    end

    add_index :notifications, :user_id
  end
end
