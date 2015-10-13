class AddIsActiveToTimer < ActiveRecord::Migration
  def change
    add_column :timers, :is_active, :boolean, null: false, default: true
  end
end
