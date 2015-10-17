class CreateFollows < ActiveRecord::Migration
  def change
    create_table :follows do |t|
      t.integer :following_user_id, null: false
      t.integer :followed_user_id, null: false

      t.timestamps null: false

      t.index :following_user_id
      t.index :followed_user_id
      t.index [:following_user_id, :followed_user_id], unique: true
    end
  end
end
