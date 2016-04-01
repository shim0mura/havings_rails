# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  item_id    :integer          not null
#  content    :text(65535)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Comment < ActiveRecord::Base

  belongs_to :item
  belongs_to :user

  default_scope -> { where(is_deleted: false) }

  def to_light
    {
      id:    self.item_id,
      name:  self.item.name,
      path:  Rails.application.routes.url_helpers.item_path(self.item_id)
    }
  end

end
