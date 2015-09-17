class Item < ActiveRecord::Base

  include EnumType

  acts_as_taggable

  enum private_type: %i(global follower friends secret)

  belongs_to :user
  has_many :item_images
  # has_many :favorites

  belongs_to :list, :class_name => "Item"
  has_many :child_items, :foreign_key => "list_id", :class_name => "Item"

  accepts_nested_attributes_for :item_images

  validates :name, presence: true

  scope :as_list, -> { where(is_list: true) }

  def is_already_listed_in?(list_id)
    lists.any? do |l|
      list_id == l.id
    end
  end

end
