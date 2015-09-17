class ChangeDefaultOfPrivateType < ActiveRecord::Migration
  def change
    change_column_default :items, :private_type, 0
  end
end
