class Item < ActiveRecord::Base

  ITEM_EVENTS = 20

  include EnumType

  acts_as_taggable

  enum private_type: %i(global follower friends secret)

  belongs_to :user
  has_many :item_images

  has_many :favorites

  has_many :comments

  belongs_to :list, :class_name => "Item"
  has_many :child_items, :foreign_key => "list_id", :class_name => "Item"

  has_many :timers, :foreign_key => "list_id"

  accepts_nested_attributes_for :item_images

  validates :name, presence: true

  default_scope -> { where(is_deleted: false) }

  scope :as_list, -> { where(is_list: true) }

  def events(from = 0, limit = ITEM_EVENTS)
    event_type = Event.event_types.select{|type|
      ["create_list", "create_item", "add_image", "dump"].include?(type)
    }.values

    if from != 0
      from_option = Event.arel_table[:id].lt(from)
      e = Event.where(from_option)
    else 
      e = Event
    end

    e
      .where(
        event_type: event_type,
        related_id: self.id,
        is_deleted: false
      )
      .order("id DESC")
      .limit(limit)
  end

  def has_next_event_from?(from)
    events(from).size > 0
  end

  def is_already_listed_in?(list_id)
    lists.any? do |l|
      list_id == l.id
    end
  end

  def is_favorited?(user_id)
    Favorite.exists?(
      user_id: user_id,
      item_id: self.id
    )
  end

  def to_light
    if item_image = self.item_images.last
      image = item_image.image_url
    else
      image = nil
    end

    {
      id:      self.id,
      name:    self.name,
      is_list: self.is_list,
      count:   self.count,
      image:   image,
      path:    Rails.application.routes.url_helpers.item_path(self.id)
    }
  end

end
