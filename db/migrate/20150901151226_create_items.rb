class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :name
      t.text :description
      t.boolean :is_list, null: false, default: false
      t.boolean :is_garbage, null: false, default: false
      t.boolean :is_private, null: false, default: false
      t.integer :count, null: false, default: 1
      t.text :garbage_reason
      t.integer :list_id

      t.timestamps null: false
    end
  end
end
