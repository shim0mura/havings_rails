class Notification < ActiveRecord::Base

  MAX_SHOWING_NOTIFICATION = 20

  belongs_to :user

  def get_showing_notification
    unread = unread_events ? JSON.parse(unread_events) : []
    already_read = read_events ? JSON.parse(read_events) : []
    if unread.size > MAX_SHOWING_NOTIFICATION
      result = Event.event_string(unread, true)
    else
      result = Event.event_string(unread, true) + Event.event_string(already_read, false)
      result = result.slice(0...MAX_SHOWING_NOTIFICATION)
    end

    return result
  end

  # 未読のイベントの追加
  # 同じタイプのイベントはまとめる
  def add_unread_event(event)
    events = unread_events ? JSON.parse(unread_events) : []
    if events.empty?
      events << event.id
    else
      latest_event = Event.find([events.first]).first

      if latest_event.event_type == event.event_type
        latest_event_ids = events.shift
        events.unshift([latest_event_ids].unshift(event.id).flatten)
      else
        events.unshift(event.id)
      end
    end

    self.unread_events = events
    save!
  end

  def read
    return true unless unread_events
    unread = JSON.parse(unread_events)
    already_read = read_events ? JSON.parse(read_events) : []
    already_read = (unread + already_read).slice(0...MAX_SHOWING_NOTIFICATION)
    self.unread_events = nil
    self.read_events = already_read.to_json
    self.save
  end

end
