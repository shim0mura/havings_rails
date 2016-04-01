class CreateCharts < ActiveRecord::Migration
  def change
    create_table :charts do |t|
      t.integer :user_id, null: false
      t.text    :chart_detail

      t.timestamps null: false
    end

    add_index :charts, :user_id, unique: true
  end
end
