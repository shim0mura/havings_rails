class NotificationsController < ApplicationController

  before_action :authenticate_user!

  def index
    @notifications = current_user.notification.get_showing_notification
  end

  def unread_count
    notification = current_user.notification
    # unread_count = notification.unread_events.present? ? JSON.parse(notification.unread_events).size : 0
    unread_event_ids = notification.unread_events.present? ? JSON.parse(notification.unread_events) : []
    unread_count = Event.where(id: unread_event_ids).size

    @notifications = (0...unread_count).map{|i| {type: "nothing"}}
    render 'index'
  end

  def read
    if current_user.notification.read
      render json: { status: :ok }
    else
      render json: { }, status: :unprocessable_entity
    end
  end

end
