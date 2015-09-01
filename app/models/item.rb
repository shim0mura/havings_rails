class Item < ActiveRecord::Base

  acts_as_taggable

  belongs_to :user
  has_many :item_images
  # has_many :favorites

  has_many :list_in, class_name: ItemList, foreign_key: :item_id
  has_many :listed,  class_name: ItemList, foreign_key: :list_id
  has_many :lists,  through: :list_in,   source: :item_list_in
  has_many :child_items, through: :listed, source: :item_list_from

  accepts_nested_attributes_for :item_images

  scope :as_list, -> { where(is_list: true) }

  def is_already_listed_in?(list_id)
    lists.any? do |l|
      list_id == l.id
    end
  end

end
