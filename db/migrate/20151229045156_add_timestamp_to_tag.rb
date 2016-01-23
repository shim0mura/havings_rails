class AddTimestampToTag < ActiveRecord::Migration
  def change
    add_timestamps(:tags, null: false)
  end
end
