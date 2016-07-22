# == Schema Information
#
# Table name: item_images
#
#  id         :integer          not null, primary key
#  image      :string(255)
#  item_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ItemImage < ActiveRecord::Base

  MAX_SHOWING_USER_ITEM_IMAGES = 10
  paginates_per 5

  belongs_to :item
  has_many :image_favorites

  mount_uploader :image, ImageUploader

  default_scope -> { where.not(item_id: nil) }

  before_create :set_default_added_at

  def set_default_added_at
    self.added_at = Time.now unless self.added_at
  end

  def is_favorited?(user_id)
    # ImageFavorite.exists?(
    #   user_id: user_id,
    #   item_id: self.item_id,
    #   item_image_id: self.id
    # )
    return false unless user_id
    image_favorites.any? do |f|
      f.user_id == user_id
    end
  end

  def to_light
    {
      id:               self.id,
      image:            self.image_url,
      item_id:          self.item_id,
      item_name:        self.item.name
    }
  end

  def self.users_item_image(user_id, from = 0)
    # return self.joins(item:[:user]).where("users.id = ?", user_id).where("item_images.id > ?", from).order("item_images.added_at DESC").limit(MAX_SHOWING_USER_ITEM_IMAGES + 1).eager_load(:item)
  end

end
