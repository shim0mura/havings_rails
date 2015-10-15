class Event < ActiveRecord::Base

  MAX_EVENT_SHOWING = 3

  include EnumType

  enum event_type: %i(create_list create_item add_image dump favorite follow comment timer done_task)

  default_scope -> { where(is_deleted: false) }

  def disable
    update_attribute(:is_deleted, true)
  end

  def item
    if self.properties
      item_id = eval(self.properties)[:item_id]
    else
      item_id = self.related_id
    end
    Item.find(item_id)
  end

  def item_images
    item_image_ids = eval(self.properties)[:item_image_ids]
    ItemImage.where(id: item_image_ids)
  end

  def self.event_string(event_ids, is_unread)
    events = self.where(id: event_ids.flatten)
    result = []
    event_ids.each do |event_id|

      if event_id.is_a?(Array)
        e = events.select{|e|event_id.include?(e.id)}
      else
        e = events.select{|e|e.id == event_id}
      end

      if e.first.event_type == "timer"
        timers = Timer
          .without_deleted
          .where(id: e.map(&:related_id))
        next if timers.empty?

        hash = {
          type: e.first.event_type,
          str: nil,
          timer: [],
          unread: is_unread
        }
        str = ""
        tasks_sub = []

        (0...timers.slice(0...MAX_EVENT_SHOWING).size).each do |i|
          tasks_sub << "__timername#{i}__"
        end
        str = tasks_sub.join(", ")

        if timers.size > MAX_EVENT_SHOWING
          str = str + "ほか#{timers.size - MAX_EVENT_SHOWING}つのタスク"
        end
        hash[:str] = str + "の期限が切れました。"

        timers.slice(0...MAX_EVENT_SHOWING).each do |timer|
          h = {
            name: timer.name,
            id: timer.list_id
          }
          hash[:timer] << h
        end

        result << hash

      end

    end

    return result
  end

end
