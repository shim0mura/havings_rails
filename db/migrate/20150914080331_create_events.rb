class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.integer :type, null: false
      t.integer :acter_id, null: false
      t.integer :suffered_user_id
      t.text :properties, null: false

      t.timestamps null: false
    end

    add_index :events, :type
    add_index :events, :acter_id
  end
end
