class Event < ActiveRecord::Base

  include EnumType

  enum event_type: %i(create_list create_item add_image dump favorite follow comment timer done_task change_count)

  default_scope -> { where(is_deleted: false) }

  scope :done_tasks, ->(timer_ids){
    where(
      event_type: Event.event_types["done_task"],
      related_id: timer_ids
    )
  }

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

  # notificationの時に一緒に表示できるか判定
  # event_typeが同じfavoriteでもitemが違うならまとめたくない
  def can_unite?(target_event)
    return false unless self.event_type == target_event.event_type

    case self.event_type
    when "favorite", "comment"
      return self.related_id == target_event.related_id
    end
  end

end
