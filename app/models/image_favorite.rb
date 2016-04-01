class ImageFavorite < ActiveRecord::Base

  belongs_to :user
  belongs_to :item
  belongs_to :item_image

  validates_uniqueness_of :user_id, scope: :item_image_id

end
