class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.integer :user_id, null: false
      t.integer :item_id, null: false
      t.text :content

      t.timestamps null: false
    end
  end
end
