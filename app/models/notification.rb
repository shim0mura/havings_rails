# == Schema Information
#
# Table name: notifications
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  unread_events :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  read_events   :string(255)
#

class Notification < ActiveRecord::Base

  MAX_SHOWING_NOTIFICATION = 20
  MAX_SHOWING_ACTER = 10
  MAX_SHOWING_ACTER_IN_WEB = 3

  belongs_to :user

  # 未読のイベントの追加
  # 同じタイプのイベントはまとめる
  def add_unread_event(event)
    unread = get_unread_events

    delete_disable_events
    if unread.empty?
      # 既読の最初が同じタイプのイベントだった場合
      # 例）unread:[], read:[timer, favorite], event:timer
      # readの最初のtimerをここで追加するeventとまとめてunreadにいれる
      # なのでreadの最初のtimerは既読から未読に移ることになる
      # 結果）unread:[[timer(event), timer(既読だったもの)]], read:[favorite]
      read = get_read_events
      latest_read_event = Event.where(id: [read].flatten).last
      p "#"*20
      p latest_read_event

      if latest_read_event && event.can_unite?(latest_read_event)
        latest_event_ids = read.shift
        unread.unshift([latest_event_ids].unshift(event.id).flatten)
        self.read_events = read
      else
        unread << event.id
      end
      
    else
      latest_event = Event.where(id: [unread.first]).last
      p "$"*20
      p latest_event

      if latest_event && event.can_unite?(latest_event)
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
    delete_disable_events

    return true unless unread_events
    unread = get_unread_events
    already_read = get_read_events
    already_read = (unread + already_read).slice(0...MAX_SHOWING_NOTIFICATION)
    self.unread_events = nil
    self.read_events = already_read.to_json
    self.save
  end

  def get_showing_notification
    unread = get_unread_events
    already_read = get_read_events
    if unread.size > MAX_SHOWING_NOTIFICATION
      
      result = create_notification_construct(unread, true)
    else
      result = create_notification_construct(unread, true) + create_notification_construct(already_read, false)
      result = result.slice(0...MAX_SHOWING_NOTIFICATION)
    end

    return result
  end

  private

  def get_unread_events
    unread_events ? JSON.parse(unread_events) : []
  end

  def get_read_events
    read_events ? JSON.parse(read_events) : []
  end

  def delete_disable_events
    unread = get_unread_events
    already_read = get_read_events
    unread_event_ids = Event.where(id: unread.flatten).collect(&:id)
    read_event_ids = Event.where(id: already_read.flatten).collect(&:id)
    sanitized_unread = []
    sanitized_read = []

    unread.each do |event_id|
      if event_id.is_a?(Array)
        a = event_id.select{|e| unread_event_ids.include?(e)}
        if a.size == 0
        elsif a.size == 1
          sanitized_unread << a.first
        else
          sanitized_unread << a
        end
      else
        sanitized_unread << event_id if unread_event_ids.include?(event_id)
      end
    end

    already_read.each do |event_id|
      if event_id.is_a?(Array)
        a = event_id.select{|e| read_event_ids.include?(e)}
        if a.size == 0
        elsif a.size == 1
          sanitized_read << a.first
        else
          sanitized_read << a
        end
      else
        sanitized_read << event_id if read_event_ids.include?(event_id)
      end
    end

    self.unread_events = sanitized_unread.slice(0...MAX_SHOWING_NOTIFICATION * 2)
    self.read_events = sanitized_read.slice(0...MAX_SHOWING_NOTIFICATION)
    self.save
  end

  def create_notification_construct(event_ids, is_unread)
    events = Event.where(id: event_ids.flatten)
    result = []

    event_ids.each do |event_id|
      if event_id.is_a?(Array)
        e = events.select{|e|event_id.include?(e.id)}
      else
        e = events.select{|e|e.id == event_id}
      end

      next unless e.present?

      event, target, type = get_notification_data(e)

      next unless can_notify?(event, target, type)

      result << get_notification_hash(event, target, type, is_unread)
    end

    return result
  end

  def get_notification_data(event)
    acter = nil
    target = nil
    type = event.first.event_type.to_sym

    case type
    when :timer
      acter = Timer
        .without_deleted
        .where(id: event.map(&:related_id))
      target = nil
    when :favorite
      acter = User.where(id: event.map(&:acter_id))
      target = Item.where(id: event.map(&:related_id))
    when :comment
      acter = User.where(id: event.map(&:acter_id))
      target = Item.where(id: event.map(&:related_id))
    when :follow
      acter = User.where(id: event.map(&:acter_id))
      target = nil
    else
    end

    [acter, target, type]
  end

  def get_notification_hash(acter, target, type, is_unread)
    hash = {
      type:   type,
      unread: is_unread,
      acter:  [],
      target: []
    }

    if acter && acter.first.respond_to?(:to_light)
      acter.slice(0...MAX_SHOWING_ACTER).each do |a|
        hash[:acter] << a.to_light
      end
    end

    if target && target.first.respond_to?(:to_light)
      target.each do |t|
        hash[:target] << t.to_light
      end
    end

    return hash
  end

  def can_notify?(acter, target, type)
    case type
    when :timer
      return acter.present?
    when :favorite
      return acter.present? && target.present?
    when :comment
      return acter.present? && target.present?
    when :follow
      return acter.present?
    else
      return false
    end
  end

end
