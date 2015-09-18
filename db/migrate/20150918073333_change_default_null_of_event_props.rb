class ChangeDefaultNullOfEventProps < ActiveRecord::Migration
  def change
    change_column_null :events, :properties, true
  end
end
