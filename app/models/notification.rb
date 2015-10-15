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
    unread = unread_events ? JSON.parse(unread_events) : []

    if unread.empty?
      # 既読の最初が同じタイプのイベントだった場合
      # 例）unread:[], read:[timer, favorite], event:timer
      # readの最初のtimerをここで追加するeventとまとめてunreadにいれる
      # なのでreadの最初のtimerは既読から未読に移ることになる
      # 結果）unread:[[timer(event), timer(既読だったもの)]], read:[favorite]
      read = read_events ? JSON.parse(read_events) : []
      latest_read_event = Event.where(id: [read.first].flatten).first

      if latest_read_event && latest_read_event.event_type == event.event_type
        latest_event_ids = read.shift
        unread.unshift([latest_event_ids].unshift(event.id).flatten)
        self.read_events = read
      else
        unread << event.id
      end
      
    else
      latest_event = Event.find([unread.first]).first

      if latest_event.event_type == event.event_type
        latest_event_ids = unread.shift
        unread.unshift([latest_event_ids].unshift(event.id).flatten)
      else
        unread.unshift(event.id)
      end
    end

    self.unread_events = unread
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
