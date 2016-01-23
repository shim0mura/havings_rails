class AddCalcAtToTimer < ActiveRecord::Migration
  def change
    add_column :timers, :latest_calc_at, :datetime, null: false
  end
end
