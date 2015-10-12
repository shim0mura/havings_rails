class ChangeColumnOfNotification < ActiveRecord::Migration
  def change
    change_column :notifications, :events, :string
    rename_column :notifications, :events, :unread_events

    add_column :notifications, :read_events, :string
  end
end
