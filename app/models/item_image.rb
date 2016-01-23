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

  belongs_to :item
  mount_uploader :image, ImageUploader

  before_create :set_default_added_at

  def set_default_added_at
    self.added_at = Time.now unless self.added_at
  end

end
