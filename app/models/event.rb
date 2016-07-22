# == Schema Information
#
# Table name: events
#
#  id               :integer          not null, primary key
#  event_type       :integer          not null
#  acter_id         :integer          not null
#  suffered_user_id :integer
#  properties       :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  related_id       :integer
#  is_deleted       :boolean          default(FALSE), not null
#

class Event < ActiveRecord::Base

  include EnumType

  CREATE_LIST    = "create_list"
  CREATE_ITEM    = "create_item"
  ADD_IMAGE      = "add_image"
  DUMP           = "dump"
  FAVORITE       = "favorite"
  IMAGE_FAVORITE = "image_favorite"
  FOLLOW         = "follow"
  COMMENT        = "comment"
  TIMER          = "timer"
  DELETE_IMAGE   = "delete_image"

  enum event_type: %i(create_list create_item add_image dump favorite follow comment timer done_task change_count image_favorite delete_image)

  default_scope -> { where(is_deleted: false) }

  scope :done_tasks, ->(timer_ids){
    where(
      event_type: Event.event_types["done_task"],
      related_id: timer_ids
    )
  }

  def self.item_related_event_types
    event_types.map do |k, v|
      v if [CREATE_LIST, CREATE_ITEM, DUMP, ADD_IMAGE].include?(k)
    end.compact
  end

  def disable
    update_attribute!(:is_deleted, true)
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
    item_image_ids = eval(self.properties)[:item_image_id]
    ItemImage.where(id: item_image_id)
  end

  # notificationの時に一緒に表示できるか判定
  # event_typeが同じfavoriteでもitemが違うならまとめたくない
  def can_unite?(target_event)
    return false unless self.event_type == target_event.event_type

    case self.event_type
    when FAVORITE, IMAGE_FAVORITE, COMMENT
      return self.related_id == target_event.related_id
    end
  end

end
