class Event < ActiveRecord::Base

  include EnumType

  enum event_type: %i(create_list create_item add_image dump like follow comment timer)

  def item
    item_id = eval(self.properties)[:item_id]
    Item.find(item_id)
  end

  def item_images
    item_image_ids = eval(self.properties)[:item_image_ids]
    ItemImage.where(id: item_image_ids)
  end

end
