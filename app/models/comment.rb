class Comment < ActiveRecord::Base

  belongs_to :item
  belongs_to :user

  def to_light
    {
      id:    self.item_id,
      name:  self.item.name,
      path:  Rails.application.routes.url_helpers.item_path(self.item_id)
    }
  end

end
