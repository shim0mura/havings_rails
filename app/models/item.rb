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
    # TODO: グラフ用のshowing_eventsと一緒にしたい
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

  def change_count(count_diff = 0, event = nil, current_list = nil)
    parent_list = current_list || self.list
    return unless parent_list

    properties = parent_list.count_properties ? JSON.parse(parent_list.count_properties) : []
    latest_date = properties.present? ? Date.parse(properties.last["date"]) : nil

    if latest_date && (latest_date == Date.today)
      hash = properties.pop
      hash["date"] = latest_date
      hash["count"] = hash["count"] + count_diff
    else
      hash = {}
      hash["date"] = Date.today
      hash["count"] = (is_list ? self.user.item_tree(nil, parent_list.id).first[:count] : self.count)
      hash["events"] = []
    end

    hash["events"] << event.id if event.present?
    properties << hash

    parent_list.count_properties = properties.to_json
    parent_list.count = hash["count"].to_i
    parent_list.save
    parent_list.change_count(count_diff) unless current_list
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

  def showing_events(relation_with_owner = 0)
    # TODO: 何日前まで取得するか決める
    properties_by_day = JSON.parse(self.count_properties)
    events = Event.where(id: properties_by_day.map{|prop|prop["events"]}.flatten)
    properties_by_day.each do |prop|
      event_ids = prop["events"]

      # count_propertiesにあるイベントと関連アイテムを全部一気に取得
      # いちいち取得してたら発行するSQLがすごい数になるから
      events_of_the_day = events.select{|e|event_ids.include?(e.id)}
      item_ids = []
      events_of_the_day.each do |e|
        if e.event_type == "add_image"
          item_ids << e.related_id
        else
          item_ids << eval(e.properties)[:item_id]
        end
      end
      items = Item.where(id: item_ids)

      # 日ごとに記録してるevent_idsをイベントオブジェクトに置き換え
      event_objects = []
      events_of_the_day.each do |e|
        hash = {}
        hash["event_type"] = e.event_type
        if e.event_type == "add_image"
          item = items.detect{|i|i.id == e.related_id}
          image_id = eval(e.properties)[:item_image_id]
          adding_image = ItemImage.where(id: image_id).first
          adding_image = adding_image.image_url if adding_image
        else
          item = items.detect{|i|i.id == eval(e.properties)[:item_id]}
        end
        hash["item"] = item.to_light if item.present?
        hash["item"]["image"] = adding_image if adding_image.present?
        event_objects << hash
      end
      prop["events"] = event_objects
    end
    properties_by_day
  end

  def can_show?(user)
    relation_to_owner = Relation::NOTHING unless user.present?
    relation_to_owner = Relation::HIMSELF if user.present? && user.id == self.user_id

    unless relation_to_owner
      followers = self.user.followed.map(&:id)
      followings = self.user.following.map(&:id)

      if followers.include?(user.id) && followings.include?(user.id)
        relation_to_owner = Relation::FRIEND
      elsif followers.include?(user.id) && !followings.include?(user.id)
        relation_to_owner = Relation::FOLLOWED
      else
        relation_to_owner = Relation::NOTHING
      end
    end

    relation_to_owner >= Item.private_types[self.private_type]
  end

end
