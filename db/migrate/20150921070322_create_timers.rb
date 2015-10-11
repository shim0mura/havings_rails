class CreateTimers < ActiveRecord::Migration
  def change
    create_table :timers do |t|
      t.string :name
      t.integer :list_id, null: false
      t.integer :user_id, null: false
      t.datetime :next_due_at, null: false
      t.datetime :over_due_from
      t.boolean :is_repeating, null: false, default: false
      t.text :properties
      t.boolean :is_deleted, null: false, default: false

      t.timestamps null: false
    end

    add_index :timers, :list_id
    add_index :timers, :user_id
  end
end
